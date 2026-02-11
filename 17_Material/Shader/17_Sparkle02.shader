Shader "B/17_Sparkle02"
{
    Properties
    {
        // 基础颜色
        _Tint ("Tint", Color) = (0.5,0.5,0.5,1)
        _ShadowColor ("Shadow Color", Color) = (0,0,0,1)
        //  闪点贴图
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSize ("Noise Size", Float) = 2
        _ShiningSpeed ("Shining Speed", Float) = 0.1
        _SparkleColor ("sparkle Color", Color) = (1,1,1,1)
        SparklePower ("sparkle Power", Float) = 10
        //  高光
        _Specular ("Specular", Range(0,1)) = 0.5
        _Gloss ("Gloss", Range(0,1) ) = 0.5
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        // 轮廓光
        _RimColor ("Rim Color", Color) = (0.17,0.36,0.81,0.0)
        _RimPower ("Rim Power", Range(0.6,36.0)) = 8.0
        _RimIntensity ("Rim Intensity", Range(0.0,100.0)) = 1.0
        // 闪点比例
        _specsparkleRate ("Specular sparkle Rate", Float) = 6
        _rimsparkleRate ("Rim sparkle Rate", Float) = 10
        _diffsparkleRate ("Diffuse sparkle Rate", Float) = 1
        // 视差贴图
        _ParallaxMap ("Parallax Map", 2D) = "white" {}
        _HeightFactor ("Height Scale", Range(-1, 1)) = 0.05
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            
            CBUFFER_START(UnityPerMaterial)
                float4 _Tint;
                float4 _ShadowColor;

                float _NoiseSize;
                float _ShiningSpeed;
                float4 _SparkleColor;
                float SparklePower;

                float _Specular;
                float _Gloss;
                float4 _SpecularColor;

                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;

                float _specsparkleRate;
                float _rimsparkleRate;
                float _diffsparkleRate;

                float _HeightFactor;
            CBUFFER_END

            // Textures
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_ParallaxMap); SAMPLER(sampler_ParallaxMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 posCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
                float3 lightDirWS : TEXCOORD4;

                // 光照和视角方向的切线空间分量
                float3 lightDir_tangent : TEXCOORD5;
                float3 viewDir_tangent : TEXCOORD6;

            };

            // 构造切线空间
            void BuildTangentSpace(float3 normalWS, float4 tangentOS, out float3 tangentWS, out float3 bitangentWS)
            {
                // 计算切线
                float3 tangentOS_xyz = tangentOS.xyz;
                tangentWS = normalize(TransformObjectToWorldDir(tangentOS_xyz));
                // bitangent sign in tangent.w
                float tangentW = tangentOS.w;
                bitangentWS = normalize(cross(normalWS, tangentWS) * tangentW);
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

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                // 位置

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.posCS = vertexInputs.positionCS;
                OUT.posWS = vertexInputs.positionWS;



                // uv
                OUT.uv = IN.uv;

                // 法线 -> 世界
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                // 视角方向 (从表面点到摄像机)
                float3 camPos = GetCameraPositionWS();
                OUT.viewDirWS = normalize(camPos - OUT.posWS);

                // 主光方向
                Light mainLight = GetMainLight();
                OUT.lightDirWS = normalize(mainLight.direction);

                // 构造切线空间
                float3 tangentWS, bitangentWS;
                BuildTangentSpace(OUT.normalWS, IN.tangentOS, tangentWS, bitangentWS);
                // TBN矩阵
                float3x3 TBN = float3x3(tangentWS, bitangentWS, OUT.normalWS);
                // 转置矩阵
                float3x3 TBN_T = transpose(TBN);
                OUT.lightDir_tangent = normalize(mul(TBN_T, OUT.lightDirWS));
                OUT.viewDir_tangent = normalize(mul(TBN_T, OUT.viewDirWS));

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // 计算法线、视角和光照方向
                float3 normalDir = normalize(IN.normalWS);
                float3 viewDir = normalize(IN.viewDirWS);
                float3 lightDir = normalize(IN.lightDirWS);

                // 衰减光照颜色
                Light mainLight = GetMainLight();
                float3 attenColor = mainLight.color.rgb;

                // 高光计算
                float specularPow = exp2((1.0 - _Gloss) * 10.0 + 1.0);
                float3 specularColor = float3(_Specular, _Specular, _Specular);
                // 高光颜色
                specularColor *= _SpecularColor.rgb;

                float3 halfVector = normalize(lightDir + viewDir);
                float3 directSpecular = pow(max(0.0, dot(halfVector, normalDir)), specularPow) * specularColor;
                float3 specular = directSpecular * attenColor;

                // 基础UV
                float2 uvBase = IN.uv;

                // 闪点 1
                float2 uvOffset1 = CaculateParallaxUV_internal(uvBase, IN.viewDir_tangent, 1.0);
                float noise1_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize + float2(0.0, _Time.y * _ShiningSpeed) + uvOffset1).r;
                float noise1_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.0) + uvOffset1).r;
                float sparkle1 = pow(noise1_1 * noise1_2 * 2.0, SparklePower);

                // 闪点 2
                float2 uvOffset2 = CaculateParallaxUV_internal(uvBase, IN.viewDir_tangent, 2.0);
                float noise2_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize + float2(0.3, _Time.y * _ShiningSpeed) + uvOffset2).r;
                float noise2_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.3) + uvOffset2).r;
                float sparkle2 = pow(noise2_1 * noise2_2 * 2.0, SparklePower);

                // 闪点 3
                float2 uvOffset3 = CaculateParallaxUV_internal(uvBase, IN.viewDir_tangent, 3.0);
                float noise3_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize + float2(0.6, _Time.y * _ShiningSpeed) + uvOffset3).r;
                float noise3_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvBase * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.6) + uvOffset3).r;
                float sparkle3 = pow(noise3_1 * noise3_2 * 2.0, SparklePower);

                // 漫反射
                float NdotL = saturate(dot(normalDir, lightDir));
                float3 directDiffuse = NdotL * attenColor;
                float3 diffuseCol = lerp(_ShadowColor.rgb, _Tint.rgb, directDiffuse);

                // 轮廓光
                float rim = 1.0 - max(0.0, dot(normalDir, viewDir));
                float3 rimCol = _RimColor.rgb * pow(rim, _RimPower) * _RimIntensity;

                // 最终颜色
                float3 sparkleCol1 = sparkle1 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * lerp(_SparkleColor.rgb, float3(1.0,1.0,1.0), 0.5);
                float3 sparkleCol2 = sparkle2 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * _SparkleColor.rgb;
                float3 sparkleCol3 = sparkle3 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * 0.5 * _SparkleColor.rgb;

                float3 finalRGB = diffuseCol + specular + sparkleCol1 + sparkleCol2 + sparkleCol3 + rimCol;


                // 输出颜色
                return half4(finalRGB, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Forward"
}
