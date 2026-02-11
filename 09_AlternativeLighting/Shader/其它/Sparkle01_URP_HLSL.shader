Shader "WalkingFat/Sparkle/Sparkle01_URP_HLSL"
{
    Properties
    {
        _Tint ("Tint", Color) = (0.5,0.5,0.5,1)
        _ShadowColor ("Shadow Color", Color) = (0,0,0,1)

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSize ("Noise Size", Float) = 2
        _ShiningSpeed ("Shining Speed", Float) = 0.1
        _SparkleColor ("Sparkle Color", Color) = (1,1,1,1)
        _SparklePower ("Sparkle Power", Float) = 10

        _Specular ("Specular", Range(0,1)) = 0.5
        _Gloss ("Gloss", Range(0,1)) = 0.5

        _RimColor ("Rim Color", Color) = (0.17,0.36,0.81,0.0)
        _RimPower ("Rim Power", Range(0.6,36.0)) = 8.0
        _RimIntensity ("Rim Intensity", Range(0.0,100.0)) = 1.0

        _SpecSparkleRate ("Specular Sparkle Rate", Float) = 6
        _RimSparkleRate ("Rim Sparkle Rate", Float) = 10
        _DiffSparkleRate ("Diffuse Sparkle Rate", Float) = 1

        _ParallaxMap ("Parallax Map", 2D) = "white" {}
        _HeightFactor ("Height Scale", Range(-1,1)) = 0.05
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // --- Texture / Samplers ---
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            float4 _NoiseTex_ST;

            TEXTURE2D(_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);
            float4 _ParallaxMap_ST;

            // --- Parameters ---
            float4 _Tint;
            float4 _ShadowColor;
            float4 _SparkleColor;
            float4 _RimColor;

            float _NoiseSize;
            float _ShiningSpeed;
            float _Specular;
            float _Gloss;
            float _RimPower;
            float _RimIntensity;
            float _SpecSparkleRate;
            float _RimSparkleRate;
            float _DiffSparkleRate;
            float _SparklePower;
            float _HeightFactor;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
                float3 lightDirWS : TEXCOORD4;
            };

            // --- Parallax Offset (tangent-based) ---
            float2 ComputeParallaxUV(Varyings i, float heightMulti)
            {
                float height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
                float2 viewDirXZ = normalize(i.viewDirWS).xz;
                return viewDirXZ * height * _HeightFactor * heightMulti;
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.uv = TRANSFORM_TEX(IN.uv, _NoiseTex);
                OUT.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - OUT.worldPos);
                OUT.lightDirWS = normalize(GetMainLight().direction);

                return OUT;
            }

            float4 Frag(Varyings IN) : SV_Target
            {
                IN.normalWS = normalize(IN.normalWS);

                // Lighting
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(IN.viewDirWS);
                float3 halfDir = normalize(lightDir + viewDir);
                float NdotL = saturate(dot(IN.normalWS, lightDir));

                float attenuation = mainLight.distanceAttenuation;
                float3 lightColor = mainLight.color * attenuation;

                // Specular
                float specPow = exp2((1 - _Gloss) * 10.0 + 1.0);
                float3 specularCol = pow(saturate(dot(IN.normalWS, halfDir)), specPow) * _Specular * lightColor;

                // Diffuse
                float3 diffuseCol = lerp(_ShadowColor.rgb, _Tint.rgb, NdotL) * lightColor;

                // Sparkle computation
                float2 uvOffset = ComputeParallaxUV(IN, 1);
                float noise1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize + float2(0, _Time.y * _ShiningSpeed) + uvOffset).r;
                float noise2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0)).r;
                float sparkle1 = pow(noise1 * noise2 * 2, _SparklePower);

                uvOffset = ComputeParallaxUV(IN, 2);
                noise1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize + float2(0.3, _Time.y * _ShiningSpeed) + uvOffset).r;
                noise2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.3)).r;
                float sparkle2 = pow(noise1 * noise2 * 2, _SparklePower);

                uvOffset = ComputeParallaxUV(IN, 3);
                noise1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize + float2(0.6, _Time.y * _ShiningSpeed) + uvOffset).r;
                noise2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.6)).r;
                float sparkle3 = pow(noise1 * noise2 * 2, _SparklePower);

                // Rim Light
                float rim = 1.0 - saturate(dot(IN.normalWS, viewDir));
                float3 rimCol = _RimColor.rgb * pow(rim, _RimPower) * _RimIntensity;

                // Combine sparkle
                float3 sparkleBase = specularCol * _SpecSparkleRate + diffuseCol * _DiffSparkleRate + rimCol * _RimSparkleRate;
                float3 sparkleCol =
                    sparkle1 * (sparkleBase * lerp(_SparkleColor.rgb, 1.0.xxx, 0.5)) +
                    sparkle2 * (sparkleBase * _SparkleColor.rgb) +
                    sparkle3 * (sparkleBase * 0.5 * _SparkleColor.rgb);

                float3 finalCol = diffuseCol + specularCol + rimCol + sparkleCol;

                return float4(finalCol, 1);
            }
            ENDHLSL
        }
    }

    FallBack Off
}
