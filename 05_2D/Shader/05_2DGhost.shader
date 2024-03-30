Shader "B/05_2DGhost"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _GhostColorBoost ("Ghost Color Boost", Range(0, 5)) = 1 //幽灵化后的亮度
        _GhostTransparency ("Ghost Transparency", Range(0, 1)) = 0 //透明度
        _GhostBlend ("Ghost Blend", Range(0, 1)) = 1 // 透明的颜色混合程度
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
            half _GhostColorBoost, _GhostTransparency, _GhostBlend;
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
                half luminance = 0.3 * col.r + 0.59 * col.g + 0.11 * col.b;//计算了当前像素的亮度（灰度值）常见的计算灰度的公式
                half4 ghostResult;
                ghostResult.a = saturate(luminance - _GhostTransparency);//计算了“幽灵效果”的透明度 从像素的亮度中减去_GhostTransparency 参数
                //计算了“幽灵效果”的颜色。它将原始颜色与像素的亮度加上_GhostColorBoost参数的乘积相乘，这样可以根据像素的亮度调整幽灵效果的颜色。
                ghostResult.rgb = col.rgb * (luminance + _GhostColorBoost);
                col = lerp(col, ghostResult, _GhostBlend);//将原始颜色和幽灵效果的颜色进行混合。混合比例由_GhostBlend参数控制

                return col;
            }
            ENDHLSL
        }
    }
}