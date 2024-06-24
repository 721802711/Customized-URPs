Shader "B/PBR/09_05_MetaMask_PBR"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _DiffuseTex("Texture", 2D) = "white" {}

        [Space(20)]
        [Header(Mask)]
        _MaskTex ("M = R R = G AO = B",2D) = "white" {}
        [Toggle]_RoughnessInvert ("_RoughnessInvert", Int) = 0
        _Metallic("_Metallic", Range(0,1)) = 0
        _MetallicIit("_MetallicIit",Range(0,5)) = 1
        _MetallicColor("_MetallicColor",Color) = (0,0,0,0)
        _Roughness("_Roughness", Range(0,1)) = 0.2
        _AO ("AO", Range(0, 1)) = 0

        [Space(20)]
        [Header(Emissive)]
        _EmissiveTex ("_EmissivTex",2D) = "white" {}
        _EmissiveInt("_EmissivInt", Float) = 1
        _EmissiveColor("_EmissivColor", Color) = (0,0,0,0)


        [Space(20)]
        [Header(Normal)]
        [Normal]_NormalTex("_NormalTex", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 1
        [Toggle]_NormalInvertG ("_NormalInvertG", Int) = 0  

        [Space(20)]
        [Header(ADDLight)]
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
        float _NormalScale,_Metallic,_Roughness,_EmissiveInt;
        float4 _BaseColor,_EmissiveColor,_MetallicColor;
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
        TEXTURE2D(_MaskTex);                         SAMPLER(sampler_MaskTex);
        TEXTURE2D(_EmissiveTex);                         SAMPLER(sampler_EmissiveTex);

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
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv);
                half emissivetex = SAMPLE_TEXTURE2D(_EmissiveTex,sampler_EmissiveTex,i.uv).r;
                mask.g = lerp(mask.g, 1 - mask.g , _RoughnessInvert);                              // 翻转粗糙度


                half3 emissive = emissivetex * albedo.rgb * _EmissiveColor.rgb * _EmissiveInt;
                half metallic = _Metallic * mask.r;
                half smoothness = _Roughness * mask.g;
                half ao = lerp(1,mask.b,_AO);
                half roughness = pow((1 - smoothness),2);


                // ============================================== 法线计算 ========================================
                float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};            // 矩阵
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal, _NormalScale);                        // 使用变量控制法线的强度
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));                        // 规范化法线 

                half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));                           // 顶点法线和法线贴图融合 = 输出世界空间法线信息
                
                // ================================================ 需要的数据  ==========================================

                half3 PBRcolor = PBR(i.viewDirWS,N,i.positionWS,albedo.rgb,roughness,metallic,ao,smoothness,emissive);
                PBRcolor += saturate((PBRcolor * mask.r) * _MetallicIit * _MetallicColor.rgb);

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