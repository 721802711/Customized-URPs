Shader "B/13_4_BakedBumpedSpecularLow"
{
    Properties
    {
         // 基础贴图
         _MainTex("Main Tex", 2D)                 = "white" {}
         _BumpTex("Bump Tex", 2D)                 = "bump" {}
         _NormalScale("NormalScale",Range(1,5))	 =1 
         // 基本光照属性
         _SpecTex("Spec Tex",2D)                 = "white"{}
         _Ambient("Ambient Color", Color)         = (0.6, 0.6, 0.6, 1.0)
         _Diffuse("Diffuse Color", Color)         = (0.7, 0.7, 0.8, 1.0)
         _Specular("Specular Color", Color)       = (1.0, 1.0, 1.0, 1.0)

         // 光源控制
         [HideInInspector]
         _UseSceneLight("Use Scene Light", Float) = 0.0
         _LightDir("Light Dir", Vector)           = (0.0, -1.0, 1.0, 0.0)
         _Shininess("Shininess",Range(0.03,1))			=0.2
         // 顶部苔藓/雪覆盖控制
         _TopUVScale("Top UV Scale", Range( 1 , 30)) = 10
         _TopIntensity("Top Intensity", Range( 0 , 1)) = 0
         _TopOffset("Top Offset", Range( 0 , 1)) = 0.5
         _TopContrast("Top Contrast", Range( 0 , 2)) = 1
         _TopNormalIntensity("Top Normal Intensity", Range( 0 , 2)) = 1 
         _TopColor("Top Color", Color) = (1,1,1,0)                      // 顶部效果的染色

         // 顶部贴图（A通道可用于控制 Smoothness 粗糙度）
         [NoScaleOffset]_TopAlbedoASmoothness("Top Albedo (A Smoothness)", 2D) = "gray" {} 
         _Top_BumpTex("Top Bump Tex", 2D)                 = "bump" {}    // 	顶部法线贴图
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" }



        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON


            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST,_BumpTex_ST,_SpecTex_ST,_TopAlbedoASmoothness_ST; 
                float4 _Ambient;
                float4 _Diffuse;
                float4 _Specular;
                // 光源控制
                float _UseSceneLight;
                float4 _LightDir;
                float _Shininess;
                float _NormalScale;
                // 顶部苔藓/雪覆盖控制
                half _TopUVScale;
                half _TopOffset;
                half _TopContrast;
                half _TopIntensity;
                half4 _TopColor;

            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpTex); SAMPLER(sampler_BumpTex);
            TEXTURE2D(_SpecTex); SAMPLER(sampler_SpecTex);
            TEXTURE2D(_TopAlbedoASmoothness); SAMPLER(sampler_TopAlbedoASmoothness);
            TEXTURE2D(_Top_BumpTex); SAMPLER(sampler_Top_BumpTex);      // 当前没有使用

            

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                float2 LightmapUV : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDir  : TEXCOORD1;
                float2 uvLightMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 vertexSH : TEXCOORD4; // 球谐光的 SH 输入
                float3x3 TBN : TEXCOORD5;
            };

            Varyings vert(Attributes input)
            {
                Varyings o;
                o.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                float3 positionWS = posInputs.positionWS;

                VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3 normalWS = normInputs.normalWS;
                float3 tangentWS = normInputs.tangentWS;
                float3 bitangentWS = normInputs.bitangentWS;

                // 获取视角
                o.viewDir = GetCameraPositionWS() - positionWS;
                float3 lightDir = float3(0.0, 0.0, 0.0);

                // 定义光照方向
                if (_UseSceneLight > 0.0)
                {
                    o.lightDir = GetMainLight().direction;     // 使用当前光源
                }
                else
                { 
                    o.lightDir = normalize(mul((float3x3)UNITY_MATRIX_I_M, -_LightDir.xyz));          // 使用自定义光源
                }

                // 定义烘培
                #ifdef LIGHTMAP_ON
                OUTPUT_LIGHTMAP_UV(input.LightmapUV, unity_LightmapST, o.uvLightMap);
                #endif

                // 球谐光 SH 光照输入
                o.vertexSH = SampleSH(normalWS);


                // 计算TBN矩阵
                float3x3 TBN;
                o.TBN[0] = tangentWS;
                o.TBN[1] = bitangentWS;
                o.TBN[2] = normalWS;

                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {

                float3 viewDir = normalize(i.viewDir);
                float3 lightDir = normalize(i.lightDir);


                // 采样纹理
                float4 normalMap = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, i.uv);
                float3 normalDir = normalize(UnpackNormalScale(normalMap, _NormalScale));


                half3 wn;
                wn.x = dot(i.TBN[0], normalMap.rgb);
                wn.y = dot(i.TBN[1], normalMap.rgb);
                wn.z = dot(i.TBN[2], normalMap.rgb);

                float s     = max(0, dot(lightDir, normalDir));
                float3 h    = normalize(viewDir + lightDir);
                float r     = max(0, dot(h, normalDir));
                float spec  = pow(r, _Shininess * 128.0);
                float4 clr  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float4 specColor = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, i.uv);


                float4 c;
                c.rgb = ((_Ambient + _Diffuse * s) * clr.rgb + spec * _Specular.rgb * clr.a * 1.5 * specColor) * 1.3;
                c.a = clr.a;


                // 顶部苔藓/雪覆盖控制
                float2 topUV = (i.uv * _TopUVScale);
                float topMask = saturate((pow((saturate(wn.y) + _TopOffset), (1.0 + (_TopContrast) * 16)) * _TopIntensity));
                float4 topTex = SAMPLE_TEXTURE2D(_TopAlbedoASmoothness, sampler_TopAlbedoASmoothness, topUV) * _TopColor;
                c = lerp(c, topTex, topMask.r);

                // 计算光照贴图
                #ifdef LIGHTMAP_ON
                half3 bakedGI = SAMPLE_GI(i.uvLightMap, i.vertexSH, normalDir);
                c.rgb *= bakedGI;
                #endif


                return c;
            }

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vertShadow
            #pragma fragment fragShadow

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vertShadow(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 lightDir = GetMainLight().direction;
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDir));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                output.positionCS = positionCS;
                return output;
            }

            float4 fragShadow(Varyings input) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }
    }
}
