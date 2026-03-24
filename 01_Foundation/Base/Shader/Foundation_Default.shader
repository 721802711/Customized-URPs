Shader "Foundation/Base/Default"
{
    Properties
    {
        _MainTex ("主纹理", 2D) = "white" {}
        _Color ("颜色", Color) = (1, 1, 1, 1)
        
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        LOD 100

        // HLSLINCLUDE: 所有Pass共享的代码
        HLSLINCLUDE
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS : TEXCOORD1;
            float2 uv : TEXCOORD0;
        };
        
        ENDHLSL

        // Pass 1: ForwardLit (主渲染)
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;

                
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInputs.normalWS;
                
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                finalColor *= _Color;
                
                return finalColor;
            }
            
            ENDHLSL
        }

    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}