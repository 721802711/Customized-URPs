Shader "B/06_20_Matrices"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

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

            // YUV to RGB matrix
            float3x3 yuv2rgb = float3x3(1.0, 0.0, 1.13983,
                                1.0, -0.39465, -0.58060,
                                1.0, 2.03211, 0.0);

            // RGB to YUV matrix
            float3x3 rgb2yuv = float3x3(0.2126, 0.7152, 0.0722,
                                -0.09991, -0.33609, 0.43600,
                                0.615, -0.5586, -0.05639);


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
                float3 rgbColor = col.rgb; // 直接获取纹理的RGB颜色
                float2 uv = i.uv;

                float3 yuvColor = float3(
                    dot(rgbColor, float3(0.299, 0.587, 0.114)),
                    rgbColor.r - 0.5, // R - 亮度值
                    rgbColor.b - 0.5  // B - 色度值
                );


                // 将2D纹理坐标转换为3D向量以进行矩阵乘法
                float3 uvExtended = float3(uv.x, uv.y, 0.5);
                float3 finalColor = mul(yuv2rgb, uvExtended);


                col.rgb += float3(uv.x,uv.y, abs(sin(_Time.y)));

                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}