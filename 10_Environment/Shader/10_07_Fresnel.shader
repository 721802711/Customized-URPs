Shader "B/10_07_Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FresnelColor("Fresnel Color",Color) = (1,1,1,1)

        _Fresnel_Fade("Fade",Range(0,10)) = 1
        _Fresnel_Intensity("Intensity",Range(0,3)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"} 

        //ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

 
            struct Attributes
            {
                float4 positionOS : POSITION;  
                half3 normalOS:NORMAL;
                float2 texcoord:TEXCOORD0;
            };
 
            struct Varyings
            {  
                float4 positionCS : SV_POSITION;
                half3 normalWS:TEXCOORD;
                float3 positionWS:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };
 
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _Fresnel_Fade;
            half _Fresnel_Intensity;
            half4 _FresnelColor;
            CBUFFER_END
 
            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);


            Varyings vert (Attributes v)
            {
                Varyings o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS; 
                o.positionWS = PositionInputs.positionWS;  

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS);
                o.normalWS = NormalInputs.normalWS;

                return o;
            }
 
            half4 frag (Varyings i) : SV_Target
            {
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos-i.positionWS);
                half dotNV = 1-saturate(dot(N,V));

                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                half4 fresnel = pow(dotNV,_Fresnel_Fade) * _Fresnel_Intensity * _FresnelColor;
                texColor += fresnel;

                return texColor;
            }
            ENDHLSL
        }
    }
}