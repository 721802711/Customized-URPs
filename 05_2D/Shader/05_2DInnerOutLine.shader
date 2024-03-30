Shader "B/05_2DInnerOutLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _InnerOutlineColor ("InnerOutlineColor", Color) = (1, 0, 0, 1) //描边线条颜色
        _InnerOutlineThickness ("OutlineThickness", Int) = 2 //描边线条的偏差值的判定像素大小
        _InnerOutlineAlpha ("InnerOutlineAlpha", Range(0, 1)) = 1 //描边线条透明度
        _InnerOutlineGlow ("InnerOutlineGlow", Range(1, 10)) = 4 //描边线条发光程度


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
            float4 _MainTex_TexelSize;
            float _InnerOutlineThickness, _InnerOutlineAlpha, _InnerOutlineGlow;
            float4 _InnerOutlineColor;
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

            //整个函数的作用就是根据传入的纹理坐标 uv 和偏移量，在纹理上进行采样，获取对应位置的像素颜色。
            float3 GetPixel(in int offsetX, in int offsetY, half2 uv) 
            {
                float2 NewUV = (uv + half2(offsetX * _MainTex_TexelSize.x, offsetY * _MainTex_TexelSize.y));
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, NewUV).rgb;
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

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);


                //对x和y轴分别取样偏移值 获取内轮廓的两个方向（水平和垂直方向）上的颜色差异值
                float3 innerT = abs(GetPixel(0, _InnerOutlineThickness, i.uv) - GetPixel(0, -_InnerOutlineThickness, i.uv));
                innerT += abs(GetPixel(_InnerOutlineThickness, 0, i.uv) - GetPixel(-_InnerOutlineThickness, 0, i.uv));

                innerT = innerT * col.a * _InnerOutlineAlpha;//控制alpha值
                //对innerT取模长再进行颜色相乘 因为innerT是当前片元与相邻片元的颜色差异值，要取模才能表示差异的大小
                col.rgb += length(innerT) * _InnerOutlineColor.rgb * _InnerOutlineGlow;


                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}