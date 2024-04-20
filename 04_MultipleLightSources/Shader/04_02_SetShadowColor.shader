Shader "B/04_02_SetShadowColor"
{
    Properties
    {
        [HDR]_DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _smoothness("smoothness",Range(0, 1)) = 1
        [HDR]_SpecularColor("_SpecularColor", Color) = (0.5,0.5,0.5,0.5)
        _AmbientColor("_AmbientColor", Color) = (1,1,1,1)
        [Toggle] _ShadowColCustom("打开自定义阴影颜色", Float) = 0
        _ShadowColor("阴影颜色", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"  " Queue" = "Transparent"}
        LOD 100
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        struct appdata
        {
	        float4 positionOS : POSITION;         //顶点信息，
	        float4 normalOS : NORMAL;             //法线信息
	        float2 texcoord : TEXCOORD0;          //uv信息
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;                  //齐次位置
            float3 positionWS : TEXCOORD1;                    //世界空间下顶点位置信息
            float3 normalWS : NORMAL;                         //世界空间下法线
            float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角
        };

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DiffuseColor,_AmbientColor,_SpecularColor, _ShadowColor;
            float _smoothness;
        CBUFFER_END


        TEXTURE2D (_MainTex);                     SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass
        {
            Tags{ "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影

            #pragma shader_feature_local _SHADOWCOLCUSTOM_ON
            // ==========================================================================================================

            half3 Lambert(half3 lightColor, half3 lightDir, half3 normal, half LightAttenuation)
            {
                half NdotL = saturate(dot(normal, lightDir));

                // 这里需要单独修改阴影颜色，所以需要把光照衰减增加进来
                #ifdef _SHADOWCOLCUSTOM_ON
                half3 radiance = lerp(_ShadowColor.rgb, lightColor, LightAttenuation * _ShadowColor.a) * NdotL;
                #else
                half3 radiance = lightColor * LightAttenuation  * NdotL;                   // 计算衰减后的光照颜色
                #endif
                return radiance;
            }

            half3 Specular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
            {
                float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
                half NdotH = half(saturate(dot(normal, halfVec)));
                half modifier = pow(max(0,NdotH), smoothness);
                half3 specularReflection = specular.rgb * modifier;
                return lightColor * specularReflection;
            }

            half3 BlinnPhongReflection(half3 albedo, Light light, half3 normal, half3 viewDir, half smoothness)
            {
 
                half3 LightDir = normalize(light.direction);                //获取光照方向
                half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
                half3 attenuatedLightColor = light.color  * LightAttenuation;                                              // 计算衰减后的光照颜色

                half3 ambient = SampleSH(normal).rgb * _AmbientColor.rgb * _AmbientColor.a;
                half3 diffuse = Lambert(light.color, LightDir, normal, LightAttenuation) * _DiffuseColor.rgb;
                half3 specular = Specular(attenuatedLightColor, LightDir, normal, viewDir, _SpecularColor, smoothness);
                half3 color = (ambient + diffuse) * albedo.rgb;
                color += specular;

                return color;
            }

            // ==========================================================================================================


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;   //  相机世界位置 - 世界空间顶点位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
            
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.positionWS.xyz));                                // 获取场景主光源
                
                half3 ViewDir = normalize(i.viewDirWS);                       //归一化视角方向
                half3 NormalDir = normalize(i.normalWS);                      

                // ==========================================================================================================

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);     //贴图采样变成3个变量

                half smoothness = exp2(10 * _smoothness + 1);
                half3 col = BlinnPhongReflection(albedo.rgb, mylight, NormalDir, ViewDir, smoothness);          // 前计算漫反射和环境光 在+ 高光

                half alpha = 1;
                // ==========================================================================================================

                return half4(col.rgb,alpha);
            }
            ENDHLSL
        }

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
                float4 positionOS : POSITION;         //改一下顶点信息，
                float4 normalOS : NORMAL;             //法线信息
            };

            struct ShadowsV2f
            {
                float4 positionCS : SV_POSITION;                  //齐次位置
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
                return output;
            }
            
            real4 frag(ShadowsV2f input): SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
        }

    }
}