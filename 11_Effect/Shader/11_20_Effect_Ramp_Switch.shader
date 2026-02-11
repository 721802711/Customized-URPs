Shader "B/11_20_Effect_Ramp_Switch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex("Ramp Texture", 2D) = "white" {} 

        _RampIntensity("Ramp Intensity", Range(0, 1)) = 1
        _BaseColor("Base Color", Color) = (1,1,1,1)
        [KeywordEnum(UV,Luminance)] _RampMode ("Ramp Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _BaseColor;
            float _RampIntensity;
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

        TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
        TEXTURE2D(_RampTex);            SAMPLER(sampler_RampTex); 


        float GetLuminance(float3 color)
        {
            return dot(color, float3(0.299, 0.587, 0.114));
        }


        ENDHLSL


        Pass
        {

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _RAMPMODE_UV  _RAMPMODE_LUMINANCE


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

                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _BaseColor;
                
                half4 col = baseCol;
                #if _RAMPMODE_UV
                    float rampUV = saturate(i.uv.y);
                    half4 rampCol = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(rampUV, 0.5));
                    col *= lerp(col, rampCol * baseCol, _RampIntensity); 

                #elif _RAMPMODE_LUMINANCE
                    float luminance = saturate(GetLuminance(baseCol.rgb));
                    half4 rampCol = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(luminance, 0.8));
                    col *= lerp(col, rampCol * baseCol, _RampIntensity);
                #endif


                return col;
            }
            ENDHLSL
        }
    }
}