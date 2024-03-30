Shader "B/05_2DColorSwap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        [NoScaleOffset] _ColorSwapTex ("Color Swap Texture", 2D) = "black" { }//换颜色用的RGB图
        [HDR]_ColorSwapRed ("Red Channel", Color) = (1, 1, 1, 1) //红色通道换成什么颜色
        _ColorSwapRedLuminosity ("Red luminosity", Range(-1, 1)) = 0.5 //红色通道影响的大小
        [HDR]_ColorSwapGreen ("Green Channel", Color) = (1, 1, 1, 1) //绿色通道换成什么颜色
        _ColorSwapGreenLuminosity ("Green luminosity", Range(-1, 1)) = 0.5 //绿色通道影响的大小
        [HDR]_ColorSwapBlue ("Blue Channel", Color) = (1, 1, 1, 1) //蓝色通道换成什么颜色
        _ColorSwapBlueLuminosity ("Blue luminosity", Range(-1, 1)) = 0.5 //蓝色通道影响的大小
        _ColorSwapBlend ("Color Swap Blend", Range(0, 1)) = 1 //颜色混合程度的大小

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
            half4 _ColorSwapRed, _ColorSwapGreen, _ColorSwapBlue;
            float _ColorSwapRedLuminosity, _ColorSwapGreenLuminosity, _ColorSwapBlueLuminosity, _ColorSwapBlend;

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

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                
                float luminance = 0.3 * col.r + 0.59 * col.g + 0.11 * col.b;//计算了当前像素的亮度（灰度值）用于一些阴影部分能看出来
                half4 swapMask = SAMPLE_TEXTURE2D(_ColorSwapTex,sampler_ColorSwapTex, i.uv);//对RGB图进行采样
                swapMask.rgb *= swapMask.a;//确保颜色交换的遮罩正确应用 RGB图没有的地方就是黑的
                half3 redSwap = _ColorSwapRed * swapMask.r * saturate(luminance + _ColorSwapRedLuminosity);//计算了红色通道的颜色交换效果
                half3 greenSwap = _ColorSwapGreen * swapMask.g * saturate(luminance + _ColorSwapGreenLuminosity);//计算了绿色通道的颜色交换效果
                half3 blueSwap = _ColorSwapBlue * swapMask.b * saturate(luminance + _ColorSwapBlueLuminosity);//计算了蓝色通道的颜色交换效果
                swapMask.rgb = col.rgb * saturate(1 - swapMask.r - swapMask.g - swapMask.b);//计算了当前片元每种颜色不参与颜色交换的程度
                col.rgb = lerp(col.rgb, swapMask.rgb + redSwap + greenSwap + blueSwap, _ColorSwapBlend);//将原始色与交换后颜色混合 可用_ColorSwapBlend调整

                return col;
            }
            ENDHLSL
        }
    }
}