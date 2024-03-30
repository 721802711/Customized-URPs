Shader "B/05_2DPixel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _PixelateSize ("Pixelate size", Range(4, 512)) = 32 //像素大小

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
            float _PixelateSize;//假设_PixelateSize的值为2，意味着每个纹理坐标会被放大两倍
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
            TEXTURE2D(_ColorSwapTex);                          SAMPLER(sampler_ColorSwapTex);

        ENDHLSL


        Pass
        {

            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]
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
                //将当前像素的纹理坐标进行放大 如果原始的纹理坐标是(0.3, 0.7),而 _PixelateSize是2，那么放大后的纹理坐标就会变成(0.6, 1.4)。
                //round()函数将放大后的纹理坐标四舍五入取整。如果放大后的纹理坐标是(0.6, 1.4)，那么经过取整后就会变成(1, 1)。再次缩小_PixelateSize 完成像素化
                i.uv = round(i.uv * _PixelateSize) / _PixelateSize;
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                clip(col.a - 0.51);//类似discard 在alpha小于0.51的时候这个像素给剔除
                return col;
            }
            ENDHLSL
        }
    }
}