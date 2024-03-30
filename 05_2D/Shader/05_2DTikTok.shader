Shader "B/05_2DTikTok"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _TikTokAmount ("TikTok Amount", Range(0, 1)) = 0.5 //左右偏移量
        _TikTokAlpha ("TikTok Alpha", Range(0, 1)) = 0.25 //重影的alpha值
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
            half _TikTokAmount, _TikTokAlpha;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
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

            float4 SampleMainTex(float2 uv)
            {

                // 采样主贴图
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.color = v.color;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SampleMainTex(i.uv);

                //这里的采样位置在当前像素的右侧，横向偏移量为_TikTokAmount/10。_TikTokAmount是一个参数，用于控制条纹的宽度。
                half4 r = SampleMainTex(i.uv + half2(_TikTokAmount / 10, 0));
                //这里的采样位置在当前像素的左侧，横向偏移量为-_TikTokAmount/10。
                half4 b = SampleMainTex(i.uv + half2(-_TikTokAmount / 10, 0));
                //首先，将红色通道（r.r），以强调右侧条纹的红色部分。
                //绿色通道（col.g）保持不变。
                //然后，将蓝色通道（b.b），以强调左侧条纹的蓝色部分。
                //最后，将当前像素的alpha值设为右侧和左侧采样像素的alpha值的最大值乘以参数_TikTokAlpha以控制alpha值
                col = half4(r.r, col.g, b.b, max(max(r.a, b.a) * _TikTokAlpha, col.a));

                return col;
            }
            ENDHLSL
        }
    }
}