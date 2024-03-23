Shader "B/04_03_MultipleLitgts"
{
    Properties
    {
        [HDR]_DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _smoothness("smoothness",Range(0, 1)) = 1
        [HDR]_SpecularColor("Specular Color", Color) = (0.5,0.5,0.5,0.5)
        _AmbientColor("Ambient Color", Color) = (1,1,1,1)
        //开关是否开启多光源效果
        [KeywordEnum(individual,many)] _AddLights ("AddLights", Float) = 0
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
	        float4 positionOS : POSITION;         //改一下顶点信息，
	        float4 normalOS : NORMAL;             //法线信息
	        float2 texcoord : TEXCOORD0;          //uv信息
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;                  //齐次位置
            float3 positionWS : TEXCOORD1;                    //世界空间下顶点位置信息
            float3 normalWS : NORMAL;     
            float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角
        };

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DiffuseColor,_AmbientColor,_SpecularColor;
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
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS   // 多光源
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影

            #pragma shader_feature  _ADDLIGHTS_INDIVIDUAL _ADDLIGHTS_MANY
            // ==========================================================================================================

            half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
            {
                half NdotL = saturate(dot(normal, lightDir));
                return lightColor * NdotL;
            }

            half3 Specular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
            {
                float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
                half NdotH = half(saturate(dot(normal, halfVec)));
                half modifier = pow(max(0,NdotH), smoothness);
                half3 specularReflection = specular.rgb * modifier;
                return lightColor * specularReflection;
            }

            // ==========================================================================================================

            half3 DLightingBased(half3 lightColor, half3 lightDir, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half2 uv)
            {

                // 漫反射                   
                half3 diffuse = Lambert(lightColor, lightDir, normalWS) * _DiffuseColor.rgb;

                // 高光计算
                half smoothness = exp2(10 * _smoothness + 1);
                half3 specular = Specular(lightColor, lightDir, normalWS, viewDirectionWS, _SpecularColor, smoothness);

                // 环境光
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv).rgb;     //贴图采样变成3个变量
                half3 ambient = SampleSH(normalWS).rgb * _AmbientColor.rgb * _AmbientColor.a;

                // 合并
                half3 color = (ambient + diffuse) * albedo.rgb;
                color += specular;

                return color;     
			}

            // ==========================================================================================================
            // 多光源计算，不需要环境光
            half3 ShadeSingleLight(Light light, half3 normalWS, half3 viewDirectionWS)
            {
                half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
                // 漫反射
                half3 diffuseColor = Lambert(light.color, light.direction, normalWS);

                // 高光
                half smoothness = exp2(10 * _smoothness + 1);
                half3 specularColor = Specular(light.color, light.direction, normalWS, viewDirectionWS, 1.0, smoothness);
  
                return (specularColor + diffuseColor) * LightAttenuation;
            }


            //第一个函数读取等光信息，世界空间下法线位置，世界空间视角位置
            half3 DLightingData(Light light, half3 normalWS, half3 viewDirectionWS, half2 uv)
            {
                half3 LightColor = light.color;    
                half3 LightDir = normalize(light.direction);                //获取光照方向
                half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
                half3 attenuatedLightColor = LightColor.rgb * LightAttenuation;                                             // 计算衰减后的光照颜色

                return DLightingBased(LightColor, LightDir, LightAttenuation, normalWS, viewDirectionWS, uv);
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
                half3 color = DLightingData(mylight, NormalDir, ViewDir, i.uv);

                half alpha = 1;
                // ==========================================================================================================
                #if _ADDLIGHTS_INDIVIDUAL

                #elif _ADDLIGHTS_MANY

                    int pixelLightCount = GetAdditionalLightsCount();            //获取副光源个数，是整数类型

                    for(int index = 0; index < pixelLightCount; index++)
                    {
                        Light light = GetAdditionalLight(index, i.positionWS);     //获取其它的副光源世界位置
                        color += ShadeSingleLight(light, NormalDir, ViewDir);
					}

                #endif
                // ==========================================================================================================

                return half4(color.rgb,alpha);
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