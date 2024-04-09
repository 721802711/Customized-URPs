Shader "B/01_UV"
{
    Properties
    {
        _powInt ("Pow Int", Float) = 2
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}
        Cull[_cull]
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _powInt;
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

            #pragma multi_compile _ _DIR_NONE _DIR_U _DIR_V

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = v.texcoord;

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float2 uv = i.uv; // 原始UV坐标
                
                float addXY = length(uv - 0.5);  
                float step5 = step(addXY, 0.5);  // 圆
                // 1 表示 白色，   0 表示黑色
                half4 col = half4(0,0,0,0);
                col = float4(uv, 0, 1);

                return addXY;
            }
            ENDHLSL
        }
    }
}