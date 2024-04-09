Shader "B/00_UVShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _tiling_U ("Tiling U",Float) = 1
        _tiling_V ("Tiling V",Float) = 1
        _offset_U ("Offset U", Float) = 0
        _offset_V ("Offset V", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _tiling_U, _tiling_V;
        float _offset_U, _offset_V;
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
                float2 tiling = float2(_tiling_U, _tiling_V); // 定义平铺次数
                float2 offset = float2(_offset_U, _offset_V); // 定义平移量

                // 平铺
                uv *= tiling;
                // 平移
                uv += offset;

                // Unity TRANSFORM_TEX 宏 就是实现这样的方法

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return col;
            }
            ENDHLSL
        }
    }
}