Shader "B/01_Phong_Extended"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _gloss ("Gloss (0..1)", Range(0,1)) = 1.0
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecIntensity ("Specular Intensity", Range(0,2)) = 1.0
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0.1,16)) = 4.0
        _RimIntensity ("Rim Intensity", Range(0,2)) = 1.0
        _DiffuseFactor ("Diffuse Factor", Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 texcoord   : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : TEXCOORD1;     // world space normal
                float3 viewDirWS : TEXCOORD2;    // view direction (from surface to camera)
                float3 positionWS : TEXCOORD3;   // world space position
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _gloss;
                float4 _SpecColor;
                float _SpecIntensity;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                float _DiffuseFactor;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                // position
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                // uv
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                // normal -> world
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));

                // view dir (from surface point to camera)
                float3 camPos = GetCameraPositionWS();
                o.viewDirWS = normalize(camPos - o.positionWS);

                return o;
            }

            // Half-Lambert diffuse
            // wrap is unused here; using classic half-lambert: ndotl*0.5 + 0.5
            float HalfLambert(float3 N, float3 L)
            {
                float ndotl = dot(N, L);
                float hl = ndotl * 0.5 + 0.5;
                return saturate(hl);
            }

            // Blinn-Phong specular
            float BlinnPhongSpec(float3 N, float3 L, float3 V, float shininess, float specIntensity)
            {
                float3 H = normalize(L + V);
                float nh = saturate(dot(N, H));
                // pow can be expensive; clamp shininess to safe range
                nh = max(nh, 0.0);
                return pow(nh, shininess) * specIntensity;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample base texture
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // main light (directional) -- valid for standard URP main directional light
                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction); // direction from surface to light
                float3 lightColor = mainLight.color.rgb;

                // normalize inputs
                float3 N = normalize(i.normalWS);
                float3 V = normalize(i.viewDirWS);
                float3 L = lightDirWS;

                // 1) Half-Lambert diffuse
                float halfLam = HalfLambert(N, L);
                float3 diffuse = baseCol.rgb * halfLam * lightColor * _DiffuseFactor;

                // 2) Blinn-Phong specular
                // map _gloss (0..1) to shininess (typical scale)
                // using an exponential mapping so small gloss -> wide, large gloss -> sharp
                // avoid negative or too-large exponents
                float shininess = lerp(8.0, 256.0, saturate(_gloss)); // adjust mapping as desired
                float spec = BlinnPhongSpec(N, L, V, shininess, _SpecIntensity);
                float3 specular = (_SpecColor.rgb * spec) * lightColor;

                // 3) Ambient (using SH coefficients if available)
                // unity_SHAr/w etc are provided by Unity; extract ambient light from their w components
                // Fallback: small constant if SH not present
                float3 ambientSH = float3(0.02, 0.02, 0.02);
                #ifdef UNITY_INSTANCING_ENABLED
                    // keep ambientSH as fallback; many URP setups provide SH constants
                #endif
                // Try to read Unity spherical harmonics (common pattern)
                #ifdef UNITY_ACCESS_SH
                    // If SH macros are available this will be replaced; else use fallback
                #endif
                // Common access pattern used previously:
                // unity_SHAr/w, unity_SHAg/w, unity_SHAb/w
                // We'll be robust: check and use these if available
                #if defined(unity_SHAr) && defined(unity_SHAg) && defined(unity_SHAb)
                    ambientSH = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                #endif

                float3 ambient = ambientSH * baseCol.rgb;

                // 4) Rim lighting
                float rimFactor = pow(1.0 - saturate(dot(V, N)), _RimPower);
                rimFactor *= _RimIntensity;
                float3 rim = _RimColor.rgb * rimFactor;

                // Compose final color: ambient + diffuse + specular + rim
                float3 color = ambient + diffuse + specular + rim;

                // simple tonemapping / clamp to avoid overflow
                color = saturate(color);

                return half4(color, baseCol.a);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
