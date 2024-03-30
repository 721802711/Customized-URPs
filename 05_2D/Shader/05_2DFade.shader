Shader "B/05_2DFade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FadeTex ("FadeTexture", 2D) = "white" { }//溶解的噪声图
        _FadeAmount ("FadeAmount", Range(0, 1)) = 0 //溶解的数值
        _FadeColor ("FadeColor", Color) = (1, 1, 0, 1) //溶解时的颜色
        _FadeBurnWidth ("Fade Burn Width", Range(0, 1)) = 0.02 //当颜色覆盖了多少的时候才开始溶解

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
            float4 _FadeTex_ST;
            float _FadeAmount, _FadeBurnWidth;
            float4 _FadeColor;
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
            TEXTURE2D(_FadeTex);                          SAMPLER(sampler_FadeTex);

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

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                float originalAlpha = col.a;//原始的alpha值

                float2 tiledUvFade = TRANSFORM_TEX(i.uv, _FadeTex);//得到噪声texture的UV坐标

                float fadeTemp = SAMPLE_TEXTURE2D(_FadeTex,sampler_FadeTex, tiledUvFade).r;//选取噪声texture的r值来进行消失的判定
                float fade = step(_FadeAmount, fadeTemp);//通过texture的r值值来进行溶解判定，高于_FadeAmount为1，反之为0
                float fadeBurn = saturate(step(_FadeAmount - _FadeBurnWidth, fadeTemp));//当颜色覆盖_FadeBurnWidth以后才开始溶解的值 也是0或1
                col.a *= fade;//让原本的颜色的alpha值和fade相乘来表示消失的部分
                col += fadeBurn * SAMPLE_TEXTURE2D(_FadeTex, sampler_FadeTex, tiledUvFade) * _FadeColor * originalAlpha * (1 - col.a);//相乘得到最后的溶解效果


                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}