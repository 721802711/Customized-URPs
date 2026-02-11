Shader "B/11_10_RefractionStandard"
{
    Properties
    {
        [Header(Base Settings)]
        _MainTex ("Base Texture", 2D) = "white" {}
        _MainTexIntensity ("MainTex Color Strength", Range(0, 2)) = 1.0 
        _MainTexOpacity ("MainTex Opacity", Range(0, 1)) = 1.0 // 控制贴图可见度
        [HDR]_BaseColor ("Base Color Tint", Color) = (1,1,1,1)

        [Header(Glass and Effects Settings)]
        _GlassEffectOpacity ("Glass Effect Opacity", Range(0, 1)) = 1.0 // 核心：控制反射+折射
        _Opacity ("Global Alpha", Range(0,1)) = 1.0 // 最终输出的 Alpha

        [Header(Normal Map)]
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Intensity", Range(0, 2)) = 1.0

        [Header(Reflection)]
        [NoScaleOffset]_ReflectionCube ("Reflection Cube", CUBE) = "" {}
        _ReflectBlur ("Reflect Blur (LOD)", Range(0, 1)) = 0
        _ReflectIntensity ("Reflect Intensity", Range(0, 5)) = 1.0

        [Header(Refraction)]
        _RefractionStrength ("Refraction Strength", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Name "DoubleSidedGlassAdvancedPass"
            
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "./RefractionStandard.hlsl"           

            ENDHLSL
        }
    }
}