Shader "B/05_2DGradient"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _GradBlend ("GradientBlend", Range(0, 1)) = 1 //颜色混合的程度
        _GradTopLeftCol ("TopLeftCol", Color) = (1, 0, 0, 1) //左上角的颜色
        _GradTopRightCol ("TopRightColor", Color) = (1, 1, 0, 1) //右上角的颜色
        _GradBottomLeftColor ("BottomLeftColor", Color) = (0, 0, 1, 1) //左下角的颜色
        _GradBottomRightColor ("BottomRightColor", Color) = (0, 1, 0, 1) //右下角的颜色
        _GradBoostX ("GradBoostX", Range(0.1, 2)) = 1.2 //左边和右边的占比
        _GradBoostY ("_GradBoostY", Range(0.1, 2)) = 1.2 //上边和下边的占比

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
            float _GradBlend, _GradBoostX, _GradBoostY;
            float4 _GradTopRightCol, _GradTopLeftCol, _GradBotRightCol, _GradBotLeftCol;
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

            // Plot a line 
            float plot(float2 uv)
            {
                return smoothstep(0.02, 0.0, abs(uv.y - uv.x));
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



                float gradXLerpFactor = saturate(pow(i.uv.x, _GradBoostX));//水平梯度的平滑因子 用pow计算，我也不知道为什么
                float gradYLerpFactor = saturate(pow(i.uv.y, _GradBoostY));//垂直梯度的平滑因子
                //根据水平和垂直方向的插值因子,以及颜色梯度的四个角色彩颜色,值通过双线性插值计算出最终的颜色梯度效果。
                float4 gradientResult = lerp(lerp(_GradBotLeftCol, _GradBotRightCol, gradXLerpFactor),
                lerp(_GradTopLeftCol, _GradTopRightCol, gradXLerpFactor), gradYLerpFactor);
                gradientResult = lerp(col, gradientResult, _GradBlend);//将颜色梯度效果与原始纹理颜色进行混合，根据_GradBlend的值进行插值。
                col.rgb = gradientResult.rgb * col.a;//将混合后的颜色应用到原始颜色的RGB分量上，同时乘以原始颜色的透明度，以确保颜色混合后的透明度正确

                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}