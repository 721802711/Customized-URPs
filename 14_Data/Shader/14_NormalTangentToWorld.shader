Shader "B/14_NormalTangentToWorld"
{
    Properties
    {
        _NormalsTex ("NormalsTex", 2D) = "bump" {}
        [Space(30)]
        _NormalsStrength ("Normals Strength", Range(0, 3)) = 0.5
        _NormalsSpeed ("Normals Speed", Range(0, 0.2)) = 0.1
        _NormalsScale ("Normals Scale", Range(0, 0.2)) = 0.1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "DepthFade.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _NormalsTex_ST;
        float4 _WaveParams, _SpecularColor;
        float _NormalsStrength, _NormalsSpeed, _NormalsScale;
        float _smoothness, _hardness;
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
            float4 positionCS : SV_POSITION;  // 裁剪空间位置
            float3 positionWS : TEXCOORD0;    // 世界空间位置
            float3 normalWS : TEXCOORD1;      // 世界空间法线
            float3 tangentWS : TEXCOORD2;     // 世界空间切线
            float3 bitangentWS : TEXCOORD3;   // 世界空间副切线
            float4 uv : TEXCOORD5;            // 纹理坐标
            float3 viewDirectionWS : TEXCOORD6; // 世界空间视角方向
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalsTex);                        SAMPLER(sampler_NormalsTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息



                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;

                o.viewDirectionWS = GetWorldSpaceNormalizeViewDir(o.positionWS);    // 世界空间视角方向
                o.uv.xy = v.texcoord;
                o.uv.zw = v.texcoord;

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                // 缩放因子
                float scale = _NormalsScale;
                float scaledHalf = 0.5 * scale;
                float reciprocalScale = 1.0 / scaledHalf;
                float speed = -0.5 * _NormalsSpeed;

                // 计算Panning UV
                float2 PanningUV1 = PanningUV(i.uv.zw, reciprocalScale, 1.0, speed, float2(0.0, 0.0));

                // 采样第二个法线纹理
                float2 PanningUV2 = PanningUV(i.uv.zw, 1.0 /_NormalsScale, 1.0, _NormalsSpeed, float2(0.0, 0.0));
            
                float4 normalTex1 = SAMPLE_TEXTURE2D(_NormalsTex, sampler_NormalsTex, PanningUV1);
                float4 normalTex2 = SAMPLE_TEXTURE2D(_NormalsTex, sampler_NormalsTex, PanningUV2);
                half3 normalTS1 = UnpackNormalScale(normalTex1, _NormalsStrength);   
                half3 normalTS2 = UnpackNormalScale(normalTex2, _NormalsStrength);

                // 法线贴图混合
                half3 normalTS = NormalBlend(normalTS1.rgb, normalTS2.rgb);

                // ==========================================================================================================

                float3x3 TBN = {i.tangentWS.xyz,i.bitangentWS.xyz,i.normalWS.xyz};          //世界空间法线方向


                float3 normalWS = mul(normalTS,TBN);                                          //顶点法线，和法线贴图融合 == 世界空间的法线信息  

                // ==========================================================================================================
                // 计算光照



                half4 col;

                col.rgb = normalWS;
                col.a = 1;

                return col;
            }
            ENDHLSL
        }
    }
}