Shader "B/05_2DShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _ShadowX ("Shadow X Axis", Range(-0.5, 0.5)) = 0.1 //x轴偏移值
        _ShadowY ("Shadow Y Axis", Range(-0.5, 0.5)) = -0.05 //y轴偏移值
        _ShadowAlpha ("Shadow Alpha", Range(0, 1)) = 0.5 //影子alpha值
        _ShadowColor ("Shadow Color", Color) = (1,1,1,1)
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
            half _ShadowX, _ShadowY, _ShadowAlpha;
            half4 _ShadowColor;
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


                float2 uvShadow = i.uv + half2(_ShadowX, _ShadowY);
                half shadowA = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,  uvShadow).a;//用偏移过的uv进行采样 并且记录alpha值 可以理解为影子的alpha

                // 设置阴影的Alpha值，确保它不会低于原始颜色的Alpha值
                shadowA = max(shadowA * _ShadowAlpha, col.a);
                half ShadowMask = max(shadowA - col.a, 0.0);
                
                // 如果当前像素是阴影部分，则改变其颜色
                if (shadowA > 0.0)
                {
                    col.rgb = lerp(col.rgb, _ShadowColor, ShadowMask);

                }

                // 确保Alpha值被设置
                col.a = shadowA;
                return col;
            }
            ENDHLSL
        }
    }
}