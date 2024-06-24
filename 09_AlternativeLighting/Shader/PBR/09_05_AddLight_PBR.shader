Shader "B/PBR/09_05_AddLight_PBR"
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
        _MetallicIit("_MetallicIit",Range(0,5)) = 1
        _MetallicColor("_MetallicColor",Color) = (0,0,0,0)
        _Roughness("_Roughness", Range(0,1)) = 1
        [Toggle(_ADDITIONALLIGHTS)] _AddLights("_AddLights", Float) = 1
        _LightInt("_LightInt", Range(0,1)) = 0.3                // 控制多光源颜色强度
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "PBR_Functions.hlsl"


        #pragma shader_feature _ADDITIONALLIGHTS
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
        float4 _BaseColor,_EmissivColor,_MetallicColor;
        float _NormalInvertG,_RoughnessInvert,_MetallicIit;
        float _AO,_LightInt;
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
                half3 emissive = albedo.rgb * emissiveTex.r * _EmissivColor.rgb * _EmissivInt;

                half metallic = _Metallic * metallicTex.r;
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

                half3 PBRcolor = PBR(i.viewDirWS,N,i.positionWS,albedo.rgb,roughness,metallic,ao,smoothness,emissive);
                PBRcolor += saturate((PBRcolor * metallicTex.r) * _MetallicIit * _MetallicColor.rgb);


                // ================================================ 多光源  ==========================================              
            #ifdef _ADDITIONALLIGHTS
                int pixelLightCount = GetAdditionalLightsCount();
                for(int index = 0; index < pixelLightCount; index++)
                {
            
                    Light light = GetAdditionalLight(index,i.positionWS);
                    PBRcolor += PBRDirectLightResult(light,i.viewDirWS,N,albedo.rgb,roughness,metallic) * _LightInt;          // 多光源计算
                    
                }
            
            #endif

                return half4(PBRcolor.rgb,1);
            }
            ENDHLSL
        }

        // 阴影计算
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