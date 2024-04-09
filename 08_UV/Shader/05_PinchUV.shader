Shader "B/05_PinchUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PinchUVAmount ("Pinch Amount", Range(0, 0.5)) = 0.35 //广角强度系数
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _PinchUVAmount;
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

                half2 centerTiled = half2(0.5,0.5);
                float2 uv = i.uv - centerTiled; // 原始UV坐标

                //用π除以这个距离，得到一个比例值，用于控制图像收缩的程度
                //(-_PinchUVAmount + 0.001)是一个用户指定的参数，用于调整收缩的强度
                half pinchInt = (PI / length(centerTiled)) * (-_PinchUVAmount + 0.001);
                //* 0.5 / atan(-pinchInt * 5)通过除以另一个arctan函数的结果，来缩放这个角度偏移，以确保在纹理中心点处没有变化
                uv = centerTiled + normalize(uv) * atan(length(uv) * - pinchInt * 10.0) * 0.5 / atan(-pinchInt * 5);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return col;
            }
            ENDHLSL
        }
    }
}