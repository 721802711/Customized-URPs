Shader "B/13_1_Tree"
{
    Properties
    {
        _DiffuseColor ("基础颜色", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_SpecularColor ("SpecularColor", Color) = (1,1,1,1)
        _smoothness ("Gloss", Range(0, 1)) = 0.5


        _BaseColorTop("亮部颜色", Color) = (1,1,1,1)
        _BaseColorBottom("暗部颜色", Color) = (1,1,1,1)

        _BaseColorMaskHeight("亮部暗部遮罩比例", Float) = 1.0
        _AOInt("AO 大小", Range(0, 3)) = 1.0


        _CutOff ("Cut Off", Range(0.0,1.0)) = 0

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
            float4 _DiffuseColor, _SpecularColor;
            float _CutOff, _smoothness;
            float4 _BaseColorBottom,_BaseColorTop;
            float _BaseColorMaskHeight, _AOInt;
        CBUFFER_END


        struct appdata
        {
            float4 positionOS: POSITION;
            float3 normalOS: NORMAL;
            float4 tangentOS: TANGENT;
            float2 texcoord      : TEXCOORD0;   // 纹理坐标
            float4 vertexColor : COLOR;
        };


        struct v2f
        {
            float2 uv        : TEXCOORD0; // 纹理坐标
            float4 positionCS: SV_POSITION;
            float3 positionWS: TEXCOORD1;
            float3 normalWS: NORMAL;
            float3 viewDirWS: TEXCOORD2;
            float4 vertexColor : COLOR;
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


            v2f vert (appdata i)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                o.normalWS = normalInput.normalWS;                                //  获取世界空间下法线信息

                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.vertexColor = i.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
                half3 viewDirWS = SafeNormalize(i.viewDirWS);

                // 光照数据
                Light mainLight = GetMainLight();
                
                float3 shadowTestPosWS = i.positionWS;
                float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
                mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);

                half LightAttenuation =  mainLight.distanceAttenuation * mainLight.shadowAttenuation;

                // 漫反射 
                half NdotL = dot(normalWS, mainLight.direction);
                half3 diffuseColor = mainLight.color * saturate(NdotL) * _DiffuseColor.rgb * _DiffuseColor.a;

                // 高光
                half3 halfDir = normalize(mainLight.direction + viewDirWS);

                half smoothness = exp2(10 * _smoothness + 1);
                half3 specularColor = mainLight.color * pow(saturate(dot(normalWS, halfDir)), smoothness) * _SpecularColor.rgb * _SpecularColor.a;

                // 颜色
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);     //贴图采样变成3个变量
                //albedo.rgb *= _DiffuseColor;


                // Y轴 法线渐变
                float albedoMask = i.normalWS.y;
                albedoMask = albedoMask/2 + 0.5;
                albedoMask*=_BaseColorMaskHeight;
                albedoMask= smoothstep(0,1,albedoMask);

                half3 albedoCol = lerp(_BaseColorBottom,_BaseColorTop,albedoMask);

                half4 color = i.vertexColor.a * _AOInt;
                //color.rgb *= _DiffuseColor;
                color.rgb *= albedoCol * _DiffuseColor;
                
                // 
                clip(albedo.b - _CutOff);

                //return color;
                return half4(albedoCol, 1.0);
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

                half AlphaTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv).b;    //获取贴图的Alpha
                clip(AlphaTex - _CutOff);
                return 0;
            }
            
            ENDHLSL
        }


    }
}