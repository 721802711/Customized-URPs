Shader "11_08_Crystal"
{
    Properties
    {
        // 基础
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("MainTex (Detail: RG Normal, BA Detail)", 2D) = "white" {}
        
        // 内部层
        _InsideColor1 ("Inside Layer1 Color", Color) = (1,1,1,1)
        _InsideColor2 ("Inside Layer2 Color", Color) = (1,1,1,1)
        _InsideIntensity1 ("Inside Intensity 1", Range(0,5)) = 1
        _InsideIntensity2 ("Inside Intensity 2", Range(0,5)) = 1
        _InsideFresnelPower ("Inside Fresnel Power", Range(0,10)) = 2
        _InsideFresnelRange ("Inside Fresnel Range", Range(0,5)) = 1
        _InsideFresnelRotation ("Inside Fresnel Rotation", Range(0,360)) = 0
        _InsideFresnelMask ("Inside Fresnel Mask", 2D) = "white" {}

        // 法线
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,2)) = 1

        // 高光
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularRange ("Specular Range", Range(0,1)) = 0.5
        _SpecularIntensity ("Specular Intensity", Range(0,5)) = 1
        _SpecularMask ("Specular Mask", 2D) = "white" {}

        // 自发光
        _EmissionTex ("Emission Map", 2D) = "black" {}
        _EmissionColor ("Emission Color", Color) = (0,0,0,0)

        // 菲涅尔
        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelRange ("Fresnel Range", Range(0,5)) = 2.5
        _FresnelIntensity ("Fresnel Intensity", Range(0,5)) = 0.5
        _FresnelPower ("Fresnel Sharpness", Range(0,15)) = 5

        // 边缘光
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimRange ("Rim Range", Range(0,10)) = 1

        // MatCap
        _MatCapTex ("MatCap Texture", 2D) = "gray" {}
        _MatCapColor ("MatCap Color", Color) = (1,1,1,1)

        // 环境反射
        _CubeMap ("Reflection Cube", CUBE) = "" {}
        _CubeMip ("Reflection Mip", Range(0,1)) = 0.5
        _CubeIntensity ("Reflection Intensity", Range(0,5)) = 1

        // AO 与透明
        _AOTex ("AO Map", 2D) = "white" {}
        _AOIntensity ("AO Strength", Range(0,2)) = 1
        _Alpha ("Transparency", Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv           : TEXCOORD0;
                float2 uv2          : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 worldPos     : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float2 uv           : TEXCOORD2;
            };

            // ===== 属性声明 =====
            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_SpecularMask);   SAMPLER(sampler_SpecularMask);
            TEXTURE2D(_EmissionTex);    SAMPLER(sampler_EmissionTex);
            TEXTURE2D(_MatCapTex);      SAMPLER(sampler_MatCapTex);
            TEXTURE2D(_AOTex);          SAMPLER(sampler_AOTex);
            TEXTURE2D(_InsideFresnelMask); SAMPLER(sampler_InsideFresnelMask);

            TEXTURECUBE(_CubeMap);      SAMPLER(sampler_CubeMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _InsideColor1;
                float4 _InsideColor2;
                float  _InsideIntensity1;
                float  _InsideIntensity2;
                float  _InsideFresnelPower;
                float  _InsideFresnelRange;
                float  _InsideFresnelRotation;

                float  _NormalIntensity;
                float4 _SpecularColor;
                float  _SpecularRange;
                float  _SpecularIntensity;

                float4 _EmissionColor;

                float4 _FresnelColor;
                float  _FresnelRange;
                float  _FresnelIntensity;
                float  _FresnelPower;

                float4 _RimColor;
                float  _RimRange;

                float4 _MatCapColor;

                float  _CubeMip;
                float  _CubeIntensity;

                float  _AOIntensity;
                float  _Alpha;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv = IN.uv;
                return OUT;
            }

            float fresnel(float3 normal, float3 viewDir, float power, float intensity)
            {
                return pow(1.0 - saturate(dot(normal, viewDir)), power) * intensity;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 viewDir = normalize(GetWorldSpaceViewDir(IN.worldPos));

                // 基础贴图
                float4 baseTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _BaseColor;

                // 法线
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                float3 normalWS = normalize(IN.normalWS + normalMap * _NormalIntensity);

                // Fresnel
                float fres = fresnel(normalWS, viewDir, _FresnelPower, _FresnelIntensity);
                float4 fresCol = fres * _FresnelColor;

                // Rim Light
                float rim = pow(1 - saturate(dot(normalWS, viewDir)), _RimRange);
                float4 rimCol = rim * _RimColor;

                // Specular
                float NdotV = saturate(dot(normalWS, viewDir));
                float spec = pow(NdotV, _SpecularRange * 128) * _SpecularIntensity;
                float4 specCol = spec * _SpecularColor * SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, IN.uv);

                // Reflection
                float3 reflDir = reflect(-viewDir, normalWS);
                float4 reflCol = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflDir, _CubeMip) * _CubeIntensity;

                // Emission
                float4 emissionCol = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, IN.uv) * _EmissionColor;

                // AO
                float ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, IN.uv).r * _AOIntensity;

                // Final Color
                float4 finalCol = baseTex + specCol + rimCol + fresCol + reflCol + emissionCol;
                finalCol.rgb *= ao;
                finalCol.a = _Alpha;

                return finalCol;
            }
            ENDHLSL
        }
    }
}
