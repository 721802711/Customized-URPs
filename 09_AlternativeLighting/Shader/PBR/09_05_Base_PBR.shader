Shader "B/PBR/09_05_Base_PBR"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _DiffuseTex("Texture", 2D) = "white" {}
        [Normal][NoScaleOffset]_NormalTex("_NormalTex", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 1
        [Toggle]_NormalInvertG ("_NormalInvertG", Int) = 0  
        [NoScaleOffset] _MetallicMap ("_MetallicMap", 2D) = "black" {}
        [NoScaleOffset] _RoughnessMap ("_RoughnessMap", 2D) = "black" {}
        [Toggle]_RoughnessInvert ("_RoughnessInvert", Int) = 0
        [NoScaleOffset] _AOMap ("_AOMap", 2D) = "black" {}
        _AO ("AO", Range(0, 1)) = 0
        [NoScaleOffset] _EmissiveMap ("Emissive (RGB)", 2D) = "black" {}
        _EmissivInt("_EmissivInt", Float) = 1
        _EmissivColor("_EmissivColor", Color) = (1,1,1,1)
        _Metallic("_Metallic", Range(0,1)) = 1
        _Roughness("_Roughness", Range(0,1)) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"


        // 接收阴影所需关键字
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                               //接受阴影
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE                       // 让这个函数（TransformWorldToShadowCoord） 得到正确的阴影坐标
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS                         //额外光源阴影
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS      //开启额外其它光源计算
        #pragma multi_compile _ _SHADOWS_SOFT                                     //软阴影


        //C缓存区
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffuseTex_ST;
        float4 _Diffuse;
        float _NormalScale,_Metallic,_Roughness,_EmissivInt;
        float4 _BaseColor,_EmissivColor;
        float _NormalInvertG,_RoughnessInvert;
        float _AO;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;                     //输入顶点
            float4 normalOS : NORMAL;                         //输入法线
            float2 texcoord : TEXCOORD0;                      //输入uv信息
            float4 tangentOS : TANGENT;                       //输入切线
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;                            //输出uv
            float4 positionCS : SV_POSITION;                  //齐次位置
            float3 positionWS : TEXCOORD1;                    //世界空间下顶点位置信息
            float3 normalWS : NORMAL;                         //世界空间下法线信息
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角

        };

        TEXTURE2D(_DiffuseTex);                          SAMPLER(sampler_DiffuseTex);
        TEXTURE2D(_NormalTex);                          SAMPLER(sampler_NormalTex);

        TEXTURE2D(_MetallicMap); SAMPLER(sampler_MetallicMap);
        TEXTURE2D(_RoughnessMap); SAMPLER(sampler_RoughnessMap);
        TEXTURE2D(_AOMap); SAMPLER(sampler_AOMap);
        TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
        TEXTURE2D(_EmissiveMap); SAMPLER(sampler_EmissiveMap);

        ENDHLSL


        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 




            // D 的方法
            float Distribution(float roughness, float nh)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness),2);                      // 这里限制最小高光点
                float D = lerpSquareRoughness / (pow((pow(nh,2) * (lerpSquareRoughness - 1) + 1), 2) * PI);           
                return D;
			}

            // G_1 
            // 直接光照 G项子项
            inline real G_subSection(half dot, half k)
            {
                return dot / lerp(dot, 1, k);
            }

            // G 的方法
            float Geometry(float roughness, float nl, float nv)
            {
                //half k = pow(roughness + 1,2)/8.0;               // 直接光的K值  

                //half k = pow(roughness,2)/2;                      // 间接光的K值

                half k = pow(1 + roughness, 2) / 8.0;
                float GLeft = G_subSection(nl,k);                   // 第一部分的 G 
                float GRight = G_subSection(nv,k);                  // 第二部分的 G
                float G = GLeft * GRight;
                return G;
			}

            // 间接光 F 的方法
            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }



            // 直接光 F的方法
            float3 FresnelEquation(float3 F0,float lh)
            {
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * lh - 6.98316) * lh);
                return F;
			}



            //间接光高光 反射探针
            real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // 计算出反射向量 
                roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity内部不是线性 调整下拟合曲线求近似
                float MidLevel = roughness * 6;                                                                    // 把粗糙度remap到0-6 7个阶级 然后进行lod采样
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
            #else
                return speColor.xyz*AO;
            #endif
            }

            half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
            {
                #ifdef UNITY_COLORSPACE_GAMMA
                half SurReduction = 1 - 0.28 * roughness * roughness;
                #else
                half SurReduction = 1 / (roughness * roughness + 1);
                #endif
                #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
                half Reflectivity = BRDFspe.x;
                #else
                half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                half GrazingTSection = saturate(Reflectivity + smoothness);
                half fre = Pow4(1 - NdotV);  
                // Lighting.hlsl 第 501 行
                // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
                return lerp(F0, GrazingTSection, fre) * SurReduction;
            }



            real3 SH_IndirectionDiff(float3 normal)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                float3 Color = SampleSH9(SHCoefficients, normal);
                return max(0, Color);
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTex);
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS.xyz = NormalInputs.tangentWS;                              //  获取世界空间下切线信息
                o.BtangentWS.xyz = NormalInputs.bitangentWS;                            //  获取世界空间下副切线信息

                o.viewDirWS = SafeNormalize(GetCameraPositionWS() - PositionInputs.positionWS);   //  相机世界位置 - 世界空间顶点位置
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // ============================================= 贴图纹理 =============================================
                half4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex,sampler_DiffuseTex,i.uv) * _BaseColor;
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
                normal.g = lerp(normal.g,1-normal.g,_NormalInvertG);                                // 切换不同平台法线

                half3 metallicTex = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv.xy).rgb;
                half3 roughnessTex = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.uv.xy).rgb;
                roughnessTex = lerp(roughnessTex.r, 1- roughnessTex , _RoughnessInvert);          // 翻转粗糙度
                half aoTex = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv.xy).r;
                half3 emissiveTex = SAMPLE_TEXTURE2D(_EmissiveMap, sampler_EmissiveMap, i.uv.xy).rgb;

                half metallic = _Metallic * metallicTex.r ;
                half smoothness = _Roughness * roughnessTex.r;
                half roughness = pow((1 - smoothness),2);

                half ao = lerp(1,aoTex, _AO);
                // ============================================== 法线计算 ========================================
                float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};            // 矩阵
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal, _NormalScale);                        // 使用变量控制法线的强度
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));                        // 规范化法线 

                half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));                           // 顶点法线和法线贴图融合 = 输出世界空间法线信息
                
                // ================================================ 需要的数据  ==========================================
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);              // 计算阴影

                Light mainLight = GetMainLight(shadowCoord);                                   // 获取光照 
                half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;        // 计算距离衰减和阴影衰减

                float3 lightColor = mainLight.color;                                 // 获取光照颜色
                

                float3 viewDir   = normalize(i.viewDirWS);
                float3 normalDir = normalize(N);
                float3 lightDir  = normalize(mainLight.direction);
                float3 halfDir   = normalize(viewDir + lightDir);
            
                float nh = max(saturate(dot(normalDir, halfDir)), 0.0001);
                float nl = max(saturate(dot(normalDir, lightDir)),0.01);
                float nv = max(saturate(dot(normalDir, viewDir)),0.01);
                float vh = max(saturate(dot(viewDir, lightDir)),0.0001);
                float hl = max(saturate(dot(halfDir, lightDir)), 0.0001);

                float3 F0 = lerp(0.04,albedo.rgb,metallic);


                // ================================================ 直接光高光反射  ==========================================

                half D = Distribution(roughness,nh);
                half G = Geometry(roughness,nl,nv);
                half3 F = FresnelEquation(F0,hl);
                
          
                float3 SpecularResult = (D * G * F) / (nv * nl * 4);
                lightColor.rgb *= atten;                         // 增加阴影 衰减
                float3 SpecColor = saturate(SpecularResult * lightColor * (nl * PI * ao));                    // 这里可以AO
                //return half4(SpecColor, 1);                 
                // ================================================ 直接光漫反射  ==========================================
                half3 emissiveColor = emissiveTex * albedo.rgb * _EmissivColor.rgb * _EmissivInt;


                float3 ks = F;
                float3 kd = (1- ks) * (1 - metallic);                   // 计算kd

                float3 diffColor = kd * albedo.rgb * lightColor * nl * atten;                          // 增加阴影 衰减                        
                diffColor += emissiveColor ;                                                       // 这里增加自发光
                // ================================================ 直接光  ==========================================
                float3 directLightResult = diffColor + SpecColor;
                //return half4(directLightResult, 1);
                // ================================================ 间接光漫反射  ==========================================
                half3 shcolor = SH_IndirectionDiff(N) * ao;                                         // 这里可以AO
                half3 indirect_ks = IndirF_Function(nv,F0,roughness);                          // 计算 ks
                half3 indirect_kd = (1 - indirect_ks) * (1 - metallic);                        // 计算kd
                half3 indirectDiffColor = shcolor * indirect_kd * albedo.rgb;
                //return half4(indirectDiffColor, 1);
                // ================================================ 间接光高光反射  ==========================================

                half3 IndirectSpeCubeColor = IndirectSpeCube(N, viewDir, roughness, ao);          // 这里可以AO   
                half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, SpecularResult, F0, nv);

                half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;

                 //return half4(IndirectSpeColor.rgb,1);
                // ================================================ 间接光  ==========================================
                half3 IndirectColor = IndirectSpeColor + indirectDiffColor;


                // ================================================ 合并光  ==========================================


                half3 finalCol = IndirectColor + directLightResult;

                return half4(finalCol.rgb,1);
            }
            ENDHLSL
        }

        Pass 
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster"}
            ColorMask 0 
            Cull [_Cull]


            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "PBR_ShadowCaster.hlsl"           // 函数库

            ENDHLSL
        }
    }
}