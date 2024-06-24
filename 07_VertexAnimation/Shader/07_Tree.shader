Shader "B/07_Tree"
{
    Properties
    {
        _DiffuseColor ("DiffuseColor", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_SpecularColor ("SpecularColor", Color) = (1,1,1,1)
        _smoothness ("Gloss", Range(0, 1)) = 0.5

        _AmbientColor ("Ambient Color", Color) = (1,1,1,1)
        _CutOff("CutOff", Range(0.0, 1)) = 0.5

        [Space(20)]
        _NoiseMap ("Noise Map", 2D) = "white" {}
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0, 0) 
        _WindSpeed ("Wind Speed", Float) = 1.2
        _WindStrength ("Wind Strength", Range(0.0, 1)) = 0.2
        _WindRotate ("Wind Rotate", Range(0.0, 1)) = 0.1

    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
       
        HLSLINCLUDE
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _DiffuseColor;
        float4 _SpecularColor, _AmbientColor;
        float _smoothness;
        float _CutOff, _WindSpeed, _WindStrength, _WindRotate;
        float4 _WindDirection;
        CBUFFER_END
        
        struct appdata
        {
            float4 positionOS: POSITION;
            float3 normalOS: NORMAL;
            float4 tangentOS: TANGENT;
            float2 texcoord      : TEXCOORD0;   // 纹理坐标
        };
        
        struct v2f
        {
            float2 uv        : TEXCOORD0; // 纹理坐标
            float4 positionCS: SV_POSITION;
            float3 positionWS: TEXCOORD1;
            float3 normalWS: NORMAL;
            float3 viewDirWS: TEXCOORD2;
            float2 offcetUV: TEXCOORD3;
        };
    
        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseMap);                          SAMPLER(sampler_NoiseMap);

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


        ENDHLSL

        Pass
        {
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            



            v2f vert (appdata i)
            {
                v2f o;

                float4 Dir = normalize(_WindDirection);

                o.offcetUV =  i.positionOS.xz + (Dir.xy * _WindSpeed * _Time.y);
                
                float noise = SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, o.offcetUV, 0).r; // 假设高度值存储在红色通道
                i.positionOS.xyz += noise * _WindStrength;


                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
                o.normalWS = normalInput.normalWS;                                //  获取世界空间下法线信息

                o.viewDirWS = GetCameraPositionWS() - positionInputs.positionWS;

                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);     
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


                float noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, i.offcetUV).r; // 假设高度值存储在红色通道    
                noise * _WindRotate; 
                float2 uv = Rotate(i.uv, 0.5, noise);

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                // 漫反射 
                half NdotL = dot(normalWS, mainLight.direction);
                half3 diffuseColor = mainLight.color * saturate(NdotL) * _DiffuseColor.rgb * _DiffuseColor.a;

                // 高光
                half3 halfDir = normalize(mainLight.direction + viewDirWS);

                half smoothness = exp2(10 * _smoothness + 1);
                half3 specularColor = mainLight.color * pow(saturate(dot(normalWS, halfDir)), smoothness) * _SpecularColor.rgb * _SpecularColor.a;


                // 环境光
                half3 ambient = SampleSH(normalWS).rgb * _AmbientColor.rgb * _AmbientColor.a;

                half3 color = ambient + (specularColor + diffuseColor) * LightAttenuation;
           
                clip(albedo.a - _CutOff);
                
               return half4(color, 1.0);

            }
            ENDHLSL      
        }


        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                float2 offcetUV    : TEXCOORD1;
            };


            float3 _LightDirection;
            float3 _LightPosition;

            float4 GetShadowPositionHClip(appdata input, float2 offset)
            {

                float noise = SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, offset, 0).r; // 假设高度值存储在红色通道
                input.positionOS.xyz += noise * _WindStrength;
                    

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

            #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
            #else
                float3 lightDirectionWS = _LightDirection;
            #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #endif

                return positionCS;
            }

            
            Varyings vert(appdata input)
            {
                Varyings output;
                    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex); 

                    float4 Dir = normalize(_WindDirection);

                    output.offcetUV =  input.positionOS.xz + (Dir.xy * _WindSpeed * _Time.y);
                    output.positionCS = GetShadowPositionHClip(input, output.offcetUV);
                return output;
            }
            
            real4 frag(Varyings input): SV_TARGET
            {

                float noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.offcetUV).r; // 假设高度值存储在红色通道    
                noise * _WindRotate; 
                float2 uv = Rotate(input.uv, 0.5, noise);

                half AlphaTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv).a;    //获取贴图的Alpha
                clip(AlphaTex - _CutOff);

                return 0;
            }
            
            ENDHLSL
        }
    }
}