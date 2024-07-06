Shader "B/00_Library"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}


        Pass
        {

            Name "ForwardLit"  
            Tags{ "LightMode" = "UniversalForward" } 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "./LitPass.hlsl"           // 函数库


            ENDHLSL
        }
    }
}