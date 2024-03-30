Shader "B/05_2DGlith"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _GlitchAmount ("Glitch Amount", Range(0, 20)) = 3 //偏差的移动范围大小
        _GlitchSize ("Glitch Size", Range(0.25, 5)) = 1 //偏差的颗粒大小

        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _cull ("cull Mode", Float) = 0 
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}

        LOD 100


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _GlitchAmount, _GlitchSize;
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

            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            //生成伪随机数
            half rand2(half2 seed, half offset) {
                //50 + (_Time % 1.0) * 12根据时间生成一个随机的float型变量
                //点乘种子向量和half2(127.1, 311.7)得到一个新的向量
                //将点乘结果传入正弦函数中，以增加随机性
                //frac用于获取浮点数的小数部分的函数 中间乘以一个很大的无规律的数再加上偏移量用于调整随机数的范围
                //将结果取余1.0，确保随机数在[0, 1)范围内
                return (frac(sin(dot(seed * floor(50 + (_Time % 1.0) * 12), half2(127.1, 311.7))) * 43758.5453123) + offset) % 1.0;
            }


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

                half4 col = float4(0.0,0.0,0.0,0.0);
                //_GlitchSize 是一个参数，用于调整纹理坐标的缩放比例。
                //将纹理坐标乘以half2(24, 19)将纹理坐标的范围缩放到合适的范围
                //然后乘以_GlitchSize，再取floor操作。最终乘以4，以增加噪声的频率
                //这样得到的是一个随机数的种子，用于产生噪声
                //用rand2生成了一个随机数
                //生成的随机数进行了立方运算，这将增加噪声的强度，使其更加明显
                //第二组操作与第一组操作类似，只是使用了不同的参数。第二组操作用于生成另一组噪声。两组噪声被乘在一起，产生更加复杂的效果
                //lineNoise 变量存储了两组噪声的乘积，它将用于扰动纹理坐标
                half lineNoise = pow(rand2(floor(i.uv * half2(24, 19) * _GlitchSize) * 4, 1), 3.0) * _GlitchAmount
                * pow(rand2(floor(i.uv * half2(38, 14) * _GlitchSize) * 4, 1), 3.0);
                //将上述生成的两组随机噪声应用到当前像素的纹理坐标上，从而产生了横向的扰动。再进行采样
                float2 uv = i.uv + half2(lineNoise * 0.02 * rand2(half2(2.0, 1), 1), 0);
                col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv + half2(lineNoise * 0.02 * rand2(half2(2.0, 1), 1), 0));


                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}