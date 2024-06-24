Shader "B/09_04_SimplePBR"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _DiffuseTex("Texture", 2D) = "white" {}
        [Normal]_NormalTex("_NormalTex", 2D) = "Bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 0
        [Toggle]_NormalInvertG ("_NormalInvertG", Int) = 0  
        _MaskTex ("M = R R = G AO = B E = Alpha",2D) = "white" {}
        _Metallic("_Metallic", Range(0,1)) = 0
        _Roughness("_Roughness", Range(0,1)) = 0.5
        [Toggle]_RoughnessInvert ("_RoughnessInvert", Int) = 0
        _AO ("AO", Range(0, 1)) = 1
        _EmissivInt("_EmissivInt", Float) = 1
        _EmissivColor("_EmissivColor", Color) = (0,0,0,1)

        [Toggle(_ADDITIONALLIGHTS)] _AddLights("_AddLights", Float) = 1                     //开启额外其它光源计算
        _LightInt("_LightInt", Range(0,1)) = 0.3

        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }


            HLSLPROGRAM


            #pragma shader_feature _ADDITIONALLIGHTS
            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS                         //额外光源阴影
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS      //开启额外其它光源计算
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影

            // 烘焙
            #pragma multi_compile _ LTGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED


            #pragma vertex vert
            #pragma fragment frag

            #include "PBR_ForwardPass.hlsl"           // 函数库

            ENDHLSL
        }
        
        
        
        Pass 
        {


		    Tags{ "LightMode" = "ShadowCaster" }
		    HLSLPROGRAM
		    #pragma vertex vertshadow
		    #pragma fragment fragshadow

            #include "PBR_ShadowCasterPass.hlsl"           // 函数库


		    ENDHLSL
		}
        
    }

}