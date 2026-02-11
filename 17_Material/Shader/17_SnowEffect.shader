Shader "B/17_BaseGlitter_01"
{
    Properties
    {
        [Header(Base Maps)]
        _MainTex ("Base Texture", 2D) = "white" {}
        _MainColor ("Tint", Color) = (1,1,1,1)
        
        [Header(Snow Settings)]
        _SnowColor ("Snow Color", Color) = (1,1,1,1)
        _SnowNoise ("Snow Mask (R)", 2D) = "gray" {} 
        _SnowLevel ("Snow Level", Range(-1, 1)) = 0.1
        _SnowBlur ("Snow Softness", Range(0.01, 0.5)) = 0.1
        _SnowDirection ("Direction (WS)", Vector) = (0, 1, 0, 0)
        _SnowOffset ("Vertex Thickness", Range(0, 0.5)) = 0.05

        [Header(Snow Surface Details)]
        [Normal] _SnowNormal ("Snow Normal", 2D) = "bump" {}
        _SnowNormalScale ("Normal Intensity", Range(0, 2)) = 1.0
        _SnowSmoothness ("Snow Smoothness", Range(0.01, 1.0)) = 0.2 // 新增：控制光泽度
        _SnowSpecColor ("Snow Specular Color", Color) = (1,1,1,1)   // 新增：高光颜色

        _NormalDetailTiling ("Detail Normal Tiling", Float) = 1.37 // 建议使用非整数以减少重复
        _NormalDetailStrength ("Detail Normal Strength", Range(0, 2)) = 0.5


        [Header(Sparkle Settings)]
        _SparkleNoise ("Sparkle Noise (R)", 2D) = "black" {} 
        _SparkleColor ("Sparkle Color", Color) = (1,1,1,1)
        _SparklePower ("Sparkle Power", Range(5, 100)) = 20
        _ShiningSpeed ("Shining Speed", Float) = 0.1
        _HeightFactor ("Parallax Scale", Range(0, 0.2)) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardLit"  
            Tags { "LightMode" = "UniversalForward" } 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "./BaseGlitterPass.hlsl"           
            ENDHLSL
        }
    }
}