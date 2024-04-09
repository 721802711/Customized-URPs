Shader "B/03_WaveUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _WaveAmount ("Wave Amount", Range(0, 25)) = 7 //采样的偏差值
        _WaveSpeed ("Wave Speed", Range(0, 25)) = 10 //波动速度
        _WaveStrength ("Wave Strength", Range(0, 25)) = 7.5 //波动的幅度大小
        _WaveX ("Wave X Axis", Range(0, 1)) = 0 //波动的原点X
        _WaveY ("Wave Y Axis", Range(0, 1)) = 0.5 //波动的原点Y
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _WaveAmount, _WaveSpeed, _WaveStrength, _WaveX, _WaveY;
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
                float2 uvWave = half2(_WaveX *  _MainTex_ST.x, _WaveY *  _MainTex_ST.y) - uv;//得到一个相对于当前像素位置的波浪向量
                uvWave.x *= _ScreenParams.x / _ScreenParams.y;//这里乘以了一个屏幕宽高比的因子，目的是在非方形屏幕上保持波浪的比例
            	float waveTime = _Time.y;

                float angWave = (sqrt(dot(uvWave, uvWave)) * _WaveAmount) - ((waveTime *  _WaveSpeed));//计算波浪的角度         
        		uv += uvWave * sin(angWave) * (_WaveStrength / 1000.0);//使用正弦函数来创建波浪效果
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return col;
            }
            ENDHLSL
        }
    }
}