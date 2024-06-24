Shader "B/06_Tree"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}

        _CutOff ("Cut Off", Range(0.0,1.0)) = 0
        [Space(20)]
        _NoiseMap ("Noise Map", 2D) = "white" {}
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0, 0) 
        _WindSpeed ("Wind Speed", Float) = 1.2
        _WindStrength ("Wind Strength", Range(0.0, 1)) = 0.2
        _WindRotate ("Wind Rotate", Range(0.0, 1)) = 0.1

    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline"="UniversalPipeline"}


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"



        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DiffuseColor;
            float _CutOff, _WindSpeed, _WindStrength, _WindRotate;
            float4 _WindDirection;
        CBUFFER_END


        struct appdata
        {
            float4 positionOS : POSITION;         //改一下顶点信息，
            float2 texcoord : TEXCOORD0;          //uv信息
        };


        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;                  //齐次位置
            float2 offcetUV : TEXCOORD2;
        };


            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseMap);                          SAMPLER(sampler_NoiseMap);
        ENDHLSL


        Pass
        {

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS   // 多光源
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影


            float2 Rotate(float2 UV, float2 Center, float Rotation)
            {
                //rotation matrix
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);

                //center rotation matrix
                float2x2 rMatrix = float2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix*2 - 1;

                //multiply the UVs by the rotation matrix
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;

                return UV;
            }



            v2f vert (appdata v)
            {
                v2f o;

                float4 Dir = normalize(_WindDirection);

                o.offcetUV =  v.positionOS.xz + (Dir * _WindSpeed * _Time.y);
                
                float noise = SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, o.offcetUV, 0).r; // 假设高度值存储在红色通道
                v.positionOS.xyz += noise * _WindStrength;


                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                
                float noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, i.offcetUV).r; // 假设高度值存储在红色通道    
                noise * _WindRotate; 
                float2 uv = Rotate(i.uv, 0.5, noise);
                // 颜色
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);     //贴图采样变成3个变量

                // ==========================================================================================================
                half3 color = albedo.rgb * _DiffuseColor.rgb; 

                clip(albedo.a - _CutOff);

                return half4(color.rgb,albedo.a);
            }
            ENDHLSL
        }

        // 阴影
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            ZWrite On 
            ZTest LEqual        
            ColorMask 0 
            Cull Back 
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            struct ShadowsAppdata
            {
                float2 texcoord : TEXCOORD0;          //uv信息
                float4 positionOS : POSITION;         //改一下顶点信息，
                float4 normalOS : NORMAL;             //法线信息
            };

            struct ShadowsV2f
            {
                float4 positionCS : SV_POSITION;                  //齐次位置
                float2 uv : TEXCOORD0;
            };

            half3 _LightDirection;
            
            ShadowsV2f vert(ShadowsAppdata input)
            {
                ShadowsV2f output;
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS.xyz));
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(posWS,normalWS, _LightDirection));
   
                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);             //输出UV坐标
                return output;
            }
            
            real4 frag(ShadowsV2f input): SV_TARGET
            {

                half AlphaTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv).a;    //获取贴图的Alpha
                clip(AlphaTex - _CutOff);
                return 0;
            }
            
            ENDHLSL
        }


    }
}