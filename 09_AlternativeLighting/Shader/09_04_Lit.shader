Shader "B/09_04_Lit"
{
    Properties
    {
        [Header(SurfaceOutput)]
        [MainTexture]_ColorMap("ColorMap",2D) = "while"{}
        [MainColor]_ColorTint("Tint",Color) = (1,1,1,1)
        _CutOff("Alpha Cutoff threshold",Range(0,1)) = 0.5
        // 法线贴图
        [NoScaleOffset][Normal] _NormalMap("NormalMap",2D) = "bump"{}
        _NormalStrength("Normal Strength",Range(0,1)) = 1

        // 金属度
        [NoScaleOffset] _MetalnessMask("Metalness Mask", 2D) = "white" {}
        _Metalness("Metalness", Range(0, 1)) = 0
        // 镜面反射
        [Toggle(_SPECULAR_SETUP)] _SpecularSetupToggle("Specular Setup", Float) = 0
        [NoScaleOffset] _SpecularMap("Specular Map", 2D) = "white" {}
        _SpecularTint("Specular Tint", Color) = (1,1,1,1)

        // 平滑度
        [NoScaleOffset] _SmoothnessMask("Smoothness Mask", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5

        // 自发光
        [NoScaleOffset] _EmissionMap("Emission map", 2D) = "white" {}
        [HDR]_EmissionTint("Emission tint", Color) = (0, 0, 0, 0)     

        // 视差贴图
        [NoScaleOffset] _ParallaxMap("Height/displacement map", 2D) = "white" {}
        _ParallaxStrength("Parallax strength", Range(0, 0.1)) = 0.005

        // 
        [NoScaleOffset] _ClearCoatMask("Clear Coat Mask", 2D) = "white" {}
        _ClearCoatStrength("Clear Coat Strength", Range(0, 1)) = 0

        // 
        [NoScaleOffset] _ClearCoatSmoothnessMask("Clear Coat Smoothness Mask", 2D) = "white" {}
        _ClearCoatSmoothness("Clear Coat Smoothness", Range(0, 1)) = 0.5


        // 透明度 和叠加模式
        [HideInInspector] _Cull("Cull mode", Float) = 2
        [HideInInspector] _SourceBlend("Source Blend", Float) = 0
        [HideInInspector] _DestBlend("Dest Blend" , Float) = 0
        [HideInInspector] _ZWrite("ZWrite", Float) = 0

        [HideInInspector] _SurfaceType("Surface Type", Float) = 0
        [HideInInspector] _BlendType("Blend type", Float) = 0
        [HideInInspector] _FaceRenderingMode("Face Rendering Type", Float) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline"  "RenderType" = "Transparent" "Queue" = "Transparent"}

        Pass  
        {
            Name "ForwardLit"  
            Tags{ "LightMode" = "UniversalForward" } 


            Blend [_SourceBlend] [_DestBlend]         // Alpha模式
            ZWrite [_ZWrite] 
            Cull [_Cull]


            HLSLPROGRAM


            #define  _NORMALMAP
            #define _CLEARCOATMAP

            #pragma shader_feature_local _ALPHA_CUTOUT   
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON


        #if UNITY_VERSION >= 202120
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
        #else
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

        #endif
            #pragma multi_compile_fragment _ _SHADOWS_SOFT 

        #if UNITY_VERSION >= 202120
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

        #endif

            #pragma vertex vert
            #pragma fragment frag

            #include "./Lit/MyLitForwardLitPass.hlsl"           // 函数库

            ENDHLSL
        }
        
        // 阴影计算
        Pass 
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster"}
            ColorMask 0 
            Cull [_Cull]


            HLSLPROGRAM

            #pragma shader_feature_local _ALPHA_CUTOUT   
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS

            #pragma vertex vert
            #pragma fragment frag

            #include "./Lit/MyLitShadowCasterPass.hlsl"           // 函数库


            ENDHLSL
        }
    }
    CustomEditor "MyLitCustomInspector"
}