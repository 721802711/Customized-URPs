Shader "B/03_08_SteepParallaxWithSoftShadow"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "bump" { }
        _NormalScale ("Normal Scale", Range(0, 3)) = 1
        _HeightMap ("_HeightMap", 2D) = "bump"{}       
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(30, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 3)) = 0.1
        _MaxLayerNum ("Max Layer Num", Float) = 50
        _MinLayerNum ("Min Layer Num", Float) = 25
        _ShadowIntensity ("Shadow Intensity", Range(0, 1)) = 0.5
        [KeywordEnum(up, down)] _Parallaxmap ("_Parallaxmap Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST,_NormalMap_ST, _HeightMap_ST;
        float _HeightScale, _NormalScale,_Gloss;
        float4 _SpecularColor, _DiffuseColor;
        float _MaxLayerNum, _MinLayerNum;
        float _ShadowIntensity;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
                float3 viewDirTS: TEXCOORD3;                                       //输出视角方向
                float3 lightDirTS : TEXCOORD2;
            };

            struct parallaxDS
            {
                float2 uv;
                float height;
            };
            TEXTURE2D (_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_NormalMap);                        SAMPLER(sampler_NormalMap);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);

            
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _PARALLAXMAP_UP _PARALLAXMAP_DOWN


            parallaxDS ParallaxMapping(float2 uv, float3 viewDir_tangent, float scale)
            {
                float3 viewDir = normalize(viewDir_tangent);

                float layerNum = lerp(_MaxLayerNum, _MinLayerNum, abs(dot(float3(0, 0, 1), viewDir)));//一点优化：根据视角来决定分层数
                float layerDepth = 1.0 / layerNum;
                float currentLayerDepth = 0.0;
                float2 deltaTexCoords = viewDir.xy / viewDir.z / layerNum * (scale * 0.1);

                float2 currentTexCoords = uv;
                float currentDepthMapValue = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, currentTexCoords).r;

                while(currentLayerDepth < currentDepthMapValue)
                {
                    currentTexCoords -= deltaTexCoords;

                    currentDepthMapValue = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, currentTexCoords, 0).r;
                    currentLayerDepth += layerDepth;
                }

                parallaxDS o;
                o.uv = currentTexCoords;
                o.height = currentLayerDepth;

                return o;
            }


            // ==========================================================================================================
            float ParallaxShadow(float3 lightDir_tangent, float2 initialUV, float initialHeight, float scale)
            {
                float3 lightDir = normalize(lightDir_tangent);

                float shadowMultiplier = 1;

                const float minLayers = 15;
                const float maxLayers = 30;

                //只算正对阳光的面
                if (dot(float3(0, 0, 1), lightDir) > 0)
                {
                    float numSamplesUnderSurface = 0;
                    shadowMultiplier = 0;
                    float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), lightDir))); //根据光线方向决定层数
                    float layerHeight = 1 / numLayers;
                    float2 texStep = (scale * 0.1) * lightDir.xy / lightDir.z / numLayers;

                    float currentLayerHeight = initialHeight - layerHeight;
                    float2 currentTexCoords = initialUV + texStep;
                    float heightFromTexture = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, currentTexCoords).r;
                    int stepIndex = 1;

                    while(currentLayerHeight > 0)
                    {
                        if (heightFromTexture < currentLayerHeight)
                        {
                            numSamplesUnderSurface += 1;
                            float newShadowMultiplier = (currentLayerHeight - heightFromTexture) * (1.0 - stepIndex / numLayers);
                            shadowMultiplier = max(shadowMultiplier, newShadowMultiplier);
                        }

                        stepIndex += 1;
                        currentLayerHeight -= layerHeight;
                        currentTexCoords += texStep;
                        heightFromTexture = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, currentTexCoords, 0).r;
                    }

                    if(numSamplesUnderSurface < 1)
                    {
                        shadowMultiplier = 1;
                    }
                    else
                    {
                        shadowMultiplier = 1.0 - shadowMultiplier;
                    }
                }

                return shadowMultiplier;
            }

            // ==========================================================================================================
            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

                Light mainLight = GetMainLight();
                float3x3 tbn = float3x3(NormalInputs.tangentWS, NormalInputs.bitangentWS, o.normalWS);;

                o.lightDirTS = mul(tbn, mainLight.direction);
                o.viewDirTS = mul(tbn, GetCameraPositionWS() - PositionInputs.positionWS); 
   
                return o;   
            }


            half4 frag (v2f i) : SV_Target
            {


                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = half4(mylight.color,1);                     //获取主光源的颜色

                half3 lightDirTS = normalize(i.lightDirTS);
                half3 viewDirTS = normalize(i.viewDirTS);                            //在这里计算  视角方向      

                // ==========================================================================================================

                parallaxDS pds = ParallaxMapping(i.uv, viewDirTS, _HeightScale);
                float2 uv = pds.uv;
                float parallaxHeight = pds.height;
                if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0) //去掉边上的一些古怪的失真，在平面上工作得挺好的
                discard;


                float shadowMultiplier = ParallaxShadow(lightDirTS, uv, parallaxHeight, _HeightScale);
                

                // ==========================================================================================================
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 NormalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                float3 normalTS = UnpackNormalScale(NormalTex,_NormalScale);             //控制法线强度


                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 


                half3 diffuseColor = LightColor * albedo.rgb * (saturate(dot(normalTS, lightDirTS)) * 0.5 + 0.5);

                half3 halfDir = normalize(viewDirTS + lightDirTS);
                half3 specularColor = LightColor * _SpecularColor.rgb * pow(saturate(dot(normalTS, halfDir)), _Gloss);
                
                half3 finalColor = ambient + (diffuseColor + specularColor) * pow(shadowMultiplier, 4.0 * _ShadowIntensity);


                
                return half4(finalColor.rgb, 1.0);

            }
            ENDHLSL
        }
    }
}