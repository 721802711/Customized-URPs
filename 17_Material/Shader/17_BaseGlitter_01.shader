Shader "B/17_BaseGlitter_01"
{
    Properties
    {
        [Space(10)]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSize ("Noise Size", Float) = 2
        _ShiningSpeed ("Shining Speed", Range(0, 1)) = 0.1
        _SparklePower ("sparkle Power", Range(0, 20)) = 10
        _SparkIntensity ("Sparkle Intensity", Range(0, 15)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _NoiseTex_ST;
        float _NoiseSize;
        float _ShiningSpeed;
        float _SparklePower;
        float _SparkIntensity;
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
            float3 positionWS : TEXCOORD1;
            float3 viewDirWS : TEXCOORD2;
        };

        TEXTURE2D(_NoiseTex);                          SAMPLER(sampler_NoiseTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag



            v2f vert (appdata v)
            {
                v2f o;
                // position
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = vertexInputs.positionCS;
                o.positionWS = vertexInputs.positionWS; 


                // uv
                o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTex);


                float3 camPos = GetCameraPositionWS();
                o.viewDirWS = normalize(camPos - o.positionWS);
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float2 uvNoise = i.uv;
                float noise1_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize + float2(0.0, _Time.y * _ShiningSpeed * 1.0)).r;
                float noise1_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed * 1.0, 0.0)).r;


                float sparkleBase = max(noise1_1 * noise1_2 * 2.0, 0.0);
                float sparkle1 = saturate(pow(sparkleBase, _SparklePower)) * _SparkIntensity;


                return sparkle1;
            }
            ENDHLSL
        }
    }
}