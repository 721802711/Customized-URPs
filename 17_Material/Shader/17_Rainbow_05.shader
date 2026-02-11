Shader "Custom/17_Rainbow_05"
{
    Properties
    {
        [Header(Base)]
        // 基础
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "bump"{}
        _NormalMap ("Normal Map", 2D) = "bump" {} // 新增法线贴图属性
        _NormalScale("Normal Scale", Range(0,2)) = 1.0

        _gloss ("Gloss", Range(0,1)) = 1.0
        _Specular ("Specular", Range(0,1)) = 0.5
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecIntensity ("Specular Intensity", Range(0,2)) = 1.0



        [Header(Rim)]
        [Space(10)]
        // Rim（边缘光）
        [HDR] _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimStrength("Rim Strength", Range(0,4)) = 1.0
        _RimSoft("Rim Softness", Range(0.1,8)) = 2.0

        [Header(Iridescent)]
        [Space(10)]
        _IrideRampMap("Iridescent Ramp Map", 2D) = "white" {}

        _IrideIntensity("Iridescent Intensity", Range(0,1.0)) = 1.0


        [Header(Sparkle)]
        [Space(10)]
        _MatCap("Mat Cap", 2D) = "white" {}
        _MatCapIntensity("Mat Cap Intensity", Range(0,1.0)) = 1.0
        

        // 闪点
        [Space(10)]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSize ("Noise Size", Float) = 2
        _ShiningSpeed ("Shining Speed", Float) = 0.1
        _SparklePower ("sparkle Power", Float) = 10
        _SparkIntensity ("Sparkle Intensity", Float) = 1.0
        _SparkleColor ("sparkle Color", Color) = (1,1,1,1)

        [Header(Noise)]
        [Space(10)]
        _HeightFactor ("Height Scale", Range(-1, 1)) = 0.05
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            // pragmas
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            // ============= include 正确顺序 ==============
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ============= 定义纹理 ==============
            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_IrideRampMap);       SAMPLER(sampler_IrideRampMap);
            TEXTURE2D(_MatCap);             SAMPLER(sampler_MatCap);
            TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap); // 声明法线贴图
            TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap); // 声明视差贴图
            TEXTURE2D(_NoiseTex);           SAMPLER(sampler_NoiseTex); // 声明噪声贴图

            // ============= 材质常量块 ==============
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalMap_ST;
                float4 _IrideRampMap_ST;
                float4 _BaseColor;
                float4 _RimColor;
                float _RimStrength;
                float _RimSoft;
                float _IrideAlphaSoft;
                float _IrideAlphaStrength;
                float _IrideRampTiling;
                float _IrideIntensity;
                float _SparkSpeed;
                float _SparkTiling;
                float _SparkThreshold;
                float _SparkContrast;
                float4 _SparkColor;
                float _ParallaxIOR;
                float4 _LightDir;
                float _IrideSpeed;
                float _MatCapIntensity;
                float _NormalScale;
                float _gloss;
                float _Specular;
                float4 _SpecColor;
                float _SpecIntensity;
                // 闪点
                float4 _NoiseTex_ST;
                float _NoiseSize;
                float _ShiningSpeed;
                float _SparklePower;
                float _SparkIntensity;
                float _HeightFactor;
                float4 _SparkleColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float4 tangentOS  : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float4 uv          : TEXCOORD0;
                float2 uv_ramp     : TEXCOORD6;
                float3 worldPos    : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDirWS   : TEXCOORD3;
                float4 tangentWS   : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
            };



            // ============= Rim =============
            float3 RimLighting(float3 V, float3 N, float rimStrength, float rimSoft, float3 rimColor)
            {
                float fresnel = saturate(dot(V, N));
                float base = saturate(1.0 - fresnel);
                // pow 的底数保证非负
                base = max(base, 0.0);
                float rimFactor = rimStrength * pow(base, rimSoft);
                return saturate(rimFactor) * rimColor;
            }

            // ============= Hash / Noise / FBM =============
            float2 hash2(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)),
                           dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            float noise2(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);

                float2 a = hash2(i + float2(0.0,0.0));
                float2 b = hash2(i + float2(1.0,0.0));
                float2 c = hash2(i + float2(0.0,1.0));
                float2 d = hash2(i + float2(1.0,1.0));

                float va = dot(a, float2(1.0, 0.0));
                float vb = dot(b, float2(1.0, 0.0));
                float vc = dot(c, float2(1.0, 0.0));
                float vd = dot(d, float2(1.0, 0.0));

                float lerpX1 = lerp(va, vb, u.x);
                float lerpX2 = lerp(vc, vd, u.x);
                return lerp(lerpX1, lerpX2, u.y);
            }

            float fbm(float2 p)
            {
                float f = 0.0;
                float amp = 0.5;
                float freq = 1.0;
                for (int i = 0; i < 4; ++i)
                {
                    f += amp * noise2(p * freq);
                    freq *= 2.0;
                    amp *= 0.5;
                }
                return f;
            }

            // 计算视差UV偏移
            float2 CaculateParallaxUV_internal(float2 baseUV, float3 viewDir_tangent, float heightMulti)
            {
                // 采样高度
                float height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, baseUV).r;
                // 计算偏移
                // 视线方向的切线空间xy分量乘以高度和缩放
                float2 offset = viewDir_tangent.xy * height * _HeightFactor * heightMulti;
                return offset;
            }



            // ============= Vertex =============
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = posInputs.positionCS;

                OUT.uv.xy = TRANSFORM_TEX(IN.uv, _MainTex); 
                OUT.uv.zw = TRANSFORM_TEX(IN.uv, _NormalMap);
                OUT.uv_ramp = TRANSFORM_TEX(IN.uv, _IrideRampMap);


                float4 wp = mul(unity_ObjectToWorld, IN.positionOS);
                OUT.worldPos = wp.xyz;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
                OUT.worldNormal = NormalInputs.normalWS;
                OUT.tangentWS = float4(NormalInputs.tangentWS, IN.tangentOS.w);
                OUT.bitangentWS = NormalInputs.bitangentWS;

                OUT.viewDirWS = normalize(_WorldSpaceCameraPos - OUT.worldPos);
                return OUT;
            }

            // ============= Fragment =============
            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv.xy;
                float2 uv_Normal = IN.uv.zw;
                float2 rampUV = IN.uv_ramp;

                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction); 
                float3 lightColor = mainLight.color.rgb;


                // 计算视图空间法线
                half4 normalMapSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv_Normal);
                half3 normalTS = UnpackNormalScale(normalMapSample, _NormalScale); // 转换法线贴图的颜色值到实际的法线向量


                // 构造切线矩阵
                float3 T = normalize(IN.tangentWS.xyz);
                float3 N = normalize(IN.worldNormal);
                float3 V = normalize(IN.viewDirWS);
                float3 L = normalize(lightDirWS);
                float3 H = normalize(L + V);
                float3 B = cross(N, T) * IN.tangentWS.w;
                float3x3 tangentMatrix = float3x3(T, B, N);


                // 使用切线矩阵将切线空间的法线转换为世界空间
                float3 normalWS = TransformTangentToWorld(normalTS, tangentMatrix);

                float2 UVandMatCap;
                UVandMatCap.x = dot(normalize(UNITY_MATRIX_IT_MV[0].xyz), normalize(normalWS));
				UVandMatCap.y = dot(normalize(UNITY_MATRIX_IT_MV[1].xyz), normalize(normalWS));


                // MatCap 
                UVandMatCap = UVandMatCap.xy * 0.5 + 0.5;
                half3 matCapColor = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, UVandMatCap).rgb; 
                matCapColor *= _MatCapIntensity;

                // 基础颜色
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float3 baseRGB = baseCol.rgb * _BaseColor.rgb;


                // 高光计算
                float specularPow = exp2((1.0 - _gloss) * 10.0 + 1.0);
                float3 specularColor = float3(_Specular, _Specular, _Specular);
                // 高光颜色
                specularColor *= _SpecColor.rgb * _SpecIntensity;
                float3 directSpecular = pow(max(0.0, dot(normalWS, H)), specularPow) * specularColor;
                float3 specular = directSpecular * lightColor;


                // 基础光照
                float3 diffuseColor = baseRGB + specular;


                // Rim 边缘光
                float3 rim = RimLighting(V, normalWS, _RimStrength, _RimSoft, _RimColor.rgb);

                // iridescent 彩虹色
                float ndotv = saturate(dot(N, V));
                float fresnel = pow(1.0 - ndotv, 3.0);
                float2 uv_ramp = half2(ndotv + rampUV.x, rampUV.y + 1.0);
                float3 irideTex = SAMPLE_TEXTURE2D(_IrideRampMap, sampler_IrideRampMap, uv_ramp).rgb;
                irideTex *= _IrideIntensity;


                // 闪点 1
                float2 uvNoise = uv;

                float noise1_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize + float2(0.0, _Time.y * _ShiningSpeed * 1.0)).r;
                float noise1_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed * 1.0, 0.0)).r;


                float sparkleBase = max(noise1_1 * noise1_2 * 2.0, 0.0);
                float sparkle1 = saturate(pow(sparkleBase, _SparklePower)) * _SparkIntensity;


                // 最终颜色
                diffuseColor += rim + irideTex + matCapColor + sparkle1 * _SparkleColor.rgb * irideTex;

                return half4(diffuseColor, baseCol.a);
            }

            ENDHLSL
        }
    }

    FallBack "Unlit/Texture"
}
