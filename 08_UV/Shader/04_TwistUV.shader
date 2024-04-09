Shader "B/04_TwistUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TwistUvAmount ("Twist Amount", Range(0, 3.1416)) = 1 //扭曲强度
        _TwistUvRadius ("Twist Radius", Range(0, 3)) = 0.75 //扭曲半径
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _TwistUvAmount, _TwistUvRadius;
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

                float2 uv = i.uv - half2(0.5, 0.5); // 原始UV坐标
                half percent = (_TwistUvRadius - length(uv)) / (_TwistUvRadius + 0.001);//计算每个像素点距离扭曲中心的百分比
                half theta = percent * percent * (2.0 * sin(_TwistUvAmount)) * 8;//根据距离百分比计算角度
                half s = sin(theta);//计算出角度对应的正弦值
                half c = cos(theta);//计算出角度对应的余弦值
                half beta = max(sign(_TwistUvRadius - length(uv)), 0);//根据距离扭曲中心的距离，确定哪些像素点需要进行扭曲
                //dot(tempUv, half2(c, -s)), dot(tempUv, half2(s, c)))是旋转矩阵旋转的算法
                //beta + tempUv * (1 - beta) 部分根据beta来控制是否应用扭曲
                uv = half2(dot(uv, half2(c, -s)), dot(uv, half2(s, c))) * beta;//这里使用了向量的点乘来实现二维旋转
                uv += half2(0.5, 0.5);//将纹理坐标还原到原始范围内


                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return col;
            }
            ENDHLSL
        }
    }
}