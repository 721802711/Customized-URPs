Shader "B/00_01_HLSLShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(up,down)] _Parallaxmap ("Parallaxmap Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;

        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _PARALLAXMAP_UP  _PARALLAXMAP_DOWN


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);


                #if _PARALLAXMAP_UP
                    // 代码块，当PARALLAXMAP_UP关键字被启用时执行
                    col = float4(1,0,0,0);
                #elif _PARALLAXMAP_DOWN
                    // 代码块，当PARALLAXMAP_DOWN关键字被启用时执行
                    col = float4(0,0,1,0);
                #endif

                return col;
            }
            ENDHLSL
        }
    }
}