Shader "B/17_Glitter"
{
    Properties
    {
        // 基础属性
        [Space(10)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        _ShadowColor ("Shadow Color", Color) = (0,0,0,1)
        _DiffuseFactor ("Diffuse Factor", Range(0,2)) = 1.0 

        [Space(10)]
        // 基础光照
        _gloss ("Gloss", Range(0,1)) = 1.0
        _Specular ("Specular", Range(0,1)) = 0.5
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecIntensity ("Specular Intensity", Range(0,2)) = 1.0

        // 边缘光
        [Space(10)]
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0.6,36.0)) = 8.0
        _RimIntensity ("Rim Intensity", Range(0.0,5.0)) = 1.0

        // parallax
        [Space(10)]
        _ParallaxMap ("Parallax Map", 2D) = "white" {}
        _HeightFactor ("Height Scale", Range(-1, 1)) = 0.05

        // 闪烁效果
        [Space(10)]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSize ("Noise Size", Float) = 2
        _ShiningSpeed ("Shining Speed", Float) = 0.1
        _SparklePower ("sparkle Power", Float) = 10

        // 闪点 
        [Space(10)]
        _SparkleColor ("sparkle Color", Color) = (1,1,1,1)
        _specsparkleRate ("Specular sparkle Rate", Float) = 6
        _rimsparkleRate ("Rim sparkle Rate", Float) = 10
        _diffsparkleRate ("Diffuse sparkle Rate", Float) = 1

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
                float4 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;     
                float3 viewDirWS : TEXCOORD2;    
                float3 positionWS : TEXCOORD3;   
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float4 _Color;
                float _DiffuseFactor;
                // 基础光照
                float _gloss;
                float _Specular;
                float4 _SpecColor;
                float _SpecIntensity;
                float4 _ShadowColor;
                // 边缘光
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                // Parallax
                float _HeightFactor;
                // 闪烁效果
                float _NoiseSize;
                float _ShiningSpeed;
                float _SparklePower;
                float4 _SparkleColor;
                float _specsparkleRate;
                float _rimsparkleRate;
                float _diffsparkleRate;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D (_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            TEXTURE2D (_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);

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




            v2f vert (appdata v)
            {
                v2f o;
                // position
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = vertexInputs.positionCS;
                o.positionWS = vertexInputs.positionWS;

                // uv
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);

                // normal -> world
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));

                // view dir (from surface point to camera)
                float3 camPos = GetCameraPositionWS();
                o.viewDirWS = normalize(camPos - o.positionWS);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction); 
                float3 lightColor = mainLight.color.rgb;

                // normalize inputs
                float3 N = normalize(i.normalWS);
                float3 V = normalize(i.viewDirWS);
                float3 L = normalize(lightDirWS);
                float3 H = normalize(L + V);



                // 高光计算
                float specularPow = exp2((1.0 - _gloss) * 10.0 + 1.0);
                float3 specularColor = float3(_Specular, _Specular, _Specular);
                // 高光颜色
                specularColor *= _SpecColor.rgb * _SpecIntensity;
                float3 directSpecular = pow(max(0.0, dot(N, H)), specularPow) * specularColor;
                float3 specular = directSpecular * lightColor;

                // 计算漫反射
                float NdotL = saturate(dot(N, L));
                float3 directDiffuse = NdotL * lightColor * baseCol.rgb * _DiffuseFactor;
                float3 diffuseCol = lerp(_ShadowColor.rgb, _Color.rgb, directDiffuse);

                // 轮廓光
                float rim = 1 - saturate(dot(N, V));
                float3 rimCol = _RimColor.rgb * pow(rim, _RimPower) * _RimIntensity;

                // 闪点 1
                float2 uvNoise = i.uv.zw;
                float2 uvOffset1 = CaculateParallaxUV_internal(uvNoise, V, 1.0);
                float noise1_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize + float2(0.0, _Time.y * _ShiningSpeed) + uvOffset1).r;
                float noise1_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.0) + uvOffset1).r;
                float sparkle1 = pow(noise1_1 * noise1_2 * 2.0, _SparklePower);

                // 闪点 2
                float2 uvOffset2 = CaculateParallaxUV_internal(uvNoise, V, 2.0);
                float noise2_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize + float2(0.3, _Time.y * _ShiningSpeed) + uvOffset2).r;
                float noise2_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.3) + uvOffset2).r;
                float sparkle2 = pow(noise2_1 * noise2_2 * 2.0, _SparklePower);

                // 闪点 3
                float2 uvOffset3 = CaculateParallaxUV_internal(uvNoise, V, 3.0);
                float noise3_1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize + float2(0.6, _Time.y * _ShiningSpeed) + uvOffset3).r;
                float noise3_2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise * _NoiseSize * 1.4 + float2(_Time.y * _ShiningSpeed, 0.6) + uvOffset3).r;
                float sparkle3 = pow(noise3_1 * noise3_2 * 2.0, _SparklePower);


                // 计算闪烁颜色
                float3 sparkleCol1 = sparkle1 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * lerp(_SparkleColor.rgb, float3(1.0,1.0,1.0), 0.5);
                float3 sparkleCol2 = sparkle2 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * _SparkleColor.rgb;
                float3 sparkleCol3 = sparkle3 * (specular * _specsparkleRate + directDiffuse * _diffsparkleRate + rimCol * _rimsparkleRate) * 0.5 * _SparkleColor.rgb;


                // 最终颜色
                float3 finalRGB = diffuseCol + specular + sparkleCol1 + sparkleCol2 + sparkleCol3 + rimCol;



                return half4(finalRGB, baseCol.a);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
