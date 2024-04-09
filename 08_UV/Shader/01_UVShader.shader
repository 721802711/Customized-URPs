Shader "B/01_UVShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HandDrawnAmount ("Hand Drawn Amount", Range(0, 20)) = 10 
        _HandDrawnSpeed ("Hand Drawn Speed", Range(1, 15)) = 5 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _HandDrawnAmount, _HandDrawnSpeed;
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

                float2 uv = i.uv; // 原始UV坐标
                
                // 通过_Time.y和_HandDrawnSpeed变量计算出一个手绘动画的速度值_HandDrawnSpeed，并使用floor函数向下取整
                _HandDrawnSpeed = floor(_Time.y * 20 * _HandDrawnSpeed);  

                // 根据原始UV坐标和计算出的速度值_HandDrawnSpeed，使用正弦sin和余弦cos函数调整UV坐标
                uv.x = sin((uv.x * _HandDrawnAmount + _HandDrawnSpeed) * 4);
                uv.y = cos((uv.y * _HandDrawnAmount + _HandDrawnSpeed) * 4);

                // 使用lerp函数将原始UV坐标i.uv和调整后的UV坐标uv进行插值，根据_HandDrawnAmount的值来决定插值的比例
                i.uv = lerp(i.uv, i.uv + uv, 0.0005 * _HandDrawnAmount);
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                return col;
            }
            ENDHLSL
        }
    }
}