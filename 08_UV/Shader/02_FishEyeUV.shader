Shader "B/02_FishEyeUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FishEyeUVAmount ("Fish Eye Amount", Range(0, 0.5)) = 0.35 //鱼眼放大系数
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _FishEyeUVAmount;
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
                
                half2 centerTiled = half2(0.5, 0.5);//定义了一个半径为0.5的中心点
                half bind = length(centerTiled);//计算了中心点到原点的距离，即中心点的模长
                half2 dF = uv - centerTiled;//计算了UV坐标与中心点的差值，即UV相对于中心点的偏移量
                half dFlen = length(dF);//计算了偏移量的模长，即输入UV相对于中心点的距离
                half fishInt = (PI / bind) * (_FishEyeUVAmount + 0.001);//计算了鱼眼效果的强度
                
                uv = centerTiled + (dF / (max(0.0001, dFlen))) * tan(dFlen * fishInt) * bind / tan(bind * fishInt);//进行了鱼眼效果的计算
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return col;
            }
            ENDHLSL
        }
    }
}