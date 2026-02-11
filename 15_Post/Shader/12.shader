Shader "Test/URP/Glitch/ImageBlock"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Amplitude ("Amplitude", Range(-1, 0)) = -0.15
        _Amount ("Amount", Range(-5, 5)) = 0.5
        _BlockSize ("Block Size", Range(0, 1)) = 0.05
        _Speed ("Speed", Range(0, 100)) = 10
        _BlockPow ("Block Size Pow", Vector) = (3, 3, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "GlitchImageBlock"
            ZWrite Off ZTest Always Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;

            float _Amplitude;
            float _Amount;
            float _BlockSize;
            float _Speed;
            float4 _BlockPow;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            inline float randomNoise(float2 seed)
            {
                return frac(sin(dot(seed * floor(_Time.y * _Speed), float2(17.13, 3.71))) * 43758.5453123);
            }

            float Noise()
            {
                float _TimeX = _Time.y;
                float splitAmout = (1.0 + sin(_TimeX * 6.0)) * 0.5;
                splitAmout *= 1.0 + sin(_TimeX * 16.0) * 0.5;
                splitAmout *= 1.0 + sin(_TimeX * 19.0) * 0.5;
                splitAmout *= 1.0 + sin(_TimeX * 27.0) * 0.5;
                splitAmout = pow(splitAmout, _Amplitude);
                splitAmout *= (0.05 * _Amount);
                return splitAmout;
            }

            float ImageBlockIntensity(Varyings i)
            {
                float2 size = lerp(1, _MainTex_TexelSize.xy, 1 - _BlockSize);
                size = floor((i.uv) / size);
                float noiseBlock = randomNoise(size);
                float displaceNoise = pow(noiseBlock, _BlockPow.x) * pow(noiseBlock, _BlockPow.y);
                return displaceNoise;
            }

            half4 SplitRGB(Varyings i)
            {
                float splitAmout = Noise() * ImageBlockIntensity(i);

                half3 finalColor;
                finalColor.r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv.x + splitAmout * randomNoise(13.0), i.uv.y)).r;
                finalColor.g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).g;
                finalColor.b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv.x - splitAmout * randomNoise(123.0), i.uv.y)).b;

                return half4(finalColor, 1.0);
            }

            half4 frag(Varyings i) : SV_Target
            {
                return SplitRGB(i);
            }

            ENDHLSL
        }
    }
}
