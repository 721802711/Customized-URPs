Shader "B/11_11_RefractiProp"
{
    Properties
    {
        [Header(Render State)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 0

        [Header(Base Settings)]
        _MainTex ("Base Texture", 2D) = "white" {}
        _MainTexIntensity ("MainTex Strength", Range(0, 2)) = 1.0 
        _MainTexOpacity ("MainTex Opacity", Range(0, 1)) = 1.0 
        [HDR]_BaseColor ("Base Color Tint", Color) = (1,1,1,1)
        _Opacity ("Global Alpha", Range(0,1)) = 1.0 

        [Header(Internal Local Texture)]
        _InternalTex ("Internal Texture Static Local", 2D) = "black" {}
        [HDR]_InternalColor ("Internal Color", Color) = (1,1,1,1)
        _InternalScale ("Internal Scale", Float) = 1.0
        _InternalIntensity ("Internal Intensity", Range(0, 5)) = 1.0

        [Header(Diamond Depth POM)]
        _HeightMap ("Height Map", 2D) = "white" {}
        _HeightScale ("Height Scale", Range(0, 1.0)) = 0.05
        _Steps ("POM Steps", Range(4, 64)) = 32

        [Header(Normal Map)]
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Intensity", Range(0, 2)) = 1.0

        [Header(Reflection and Refraction Cube)]
        [NoScaleOffset]_ReflectionCube ("Reflection Cube", CUBE) = "" {}
        _ReflectBlur ("Reflect Blur LOD", Range(0, 1)) = 0
        _ReflectIntensity ("Reflect Intensity", Range(0, 5)) = 1.0
        _ReflectHDRClamp ("Reflect HDR Clamp", Float) = 10.0

        [Header(Fresnel Diamond Sparkle)]
        [HDR]_FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 5.0 

        [Header(Screen Refraction)]
        _GlassEffectOpacity ("Effect Strength", Range(0, 1)) = 1.0
        _RefractionStrength ("Screen Refraction Strength", Range(0, 0.1)) = 0.02
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float4 _HeightMap_ST;
            float4 _InternalTex_ST;
            half4  _BaseColor;
            half   _MainTexIntensity;
            half   _MainTexOpacity;
            half   _Opacity;
            half4  _InternalColor;
            float  _InternalScale;
            half   _InternalIntensity;
            half   _ReflectBlur;
            half   _ReflectIntensity;
            half   _ReflectHDRClamp;
            half4  _FresnelColor;
            half   _FresnelPower;
            half   _NormalScale;
            half   _RefractionStrength;
            half   _GlassEffectOpacity; 
            float  _HeightScale;
            float  _Steps;
        CBUFFER_END

        TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);
        TEXTURE2D(_InternalTex);      SAMPLER(sampler_InternalTex);
        TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_HeightMap);        SAMPLER(sampler_HeightMap);
        TEXTURECUBE(_ReflectionCube); SAMPLER(sampler_ReflectionCube);

        struct Attributes {
            float4 positionOS : POSITION; 
            float2 uv         : TEXCOORD0;
            float3 normalOS   : NORMAL;
            float4 tangentOS  : TANGENT;
            half4  color      : COLOR; 
        };

        struct Varyings {
            float4 positionCS : SV_POSITION;
            float2 uv         : TEXCOORD0;
            float3 normalWS   : TEXCOORD1;
            float3 positionWS : TEXCOORD2;
            float3 positionOS : TEXCOORD6; // 模型局部坐标
            float4 tangentWS  : TEXCOORD3; 
            float4 screenPos  : TEXCOORD4;
            half4  vertexColor: TEXCOORD5;
        };

        float2 ParallaxMapping(float2 uv, float3 viewDirTS) {
            float layerDepth = 1.0 / max(_Steps, 1.0);
            float currentLayerDepth = 0.0;
            float2 deltaUV = viewDirTS.xy * _HeightScale / (viewDirTS.z * _Steps + 0.01);
            float2 currentUV = uv;
            float currentHeight = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, currentUV, 0).r;

            for (int i = 0; i < 64; i++) {
                if (i >= (int)_Steps) break;
                if (currentLayerDepth >= currentHeight) break;
                currentUV -= deltaUV;
                currentHeight = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, currentUV, 0).r;
                currentLayerDepth += layerDepth;
            }
            return currentUV;
        }
        ENDHLSL

        // Pass 1: 内部折射 Pass
        Pass {
            Name "DiamondInternal"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front
            ZWrite Off
            Blend One One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Varyings vert(Attributes v) {
                Varyings o = (Varyings)0;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            half4 frag(Varyings i) : SV_Target {
                float3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
                float3 normalWS = normalize(i.normalWS); 
                float3 reflectDir = reflect(-viewDirWS, normalWS);
                half3 internalRefra = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, reflectDir, 0).rgb;
                return half4(internalRefra * _BaseColor.rgb * 0.5, _Opacity);
            }
            ENDHLSL
        }

        // Pass 2: 正面 Pass
        Pass {
            Name "DiamondForward"
            Tags { "LightMode" = "UniversalForward" }
            Cull [_Cull]
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Varyings vert(Attributes v) {
                Varyings o = (Varyings)0;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;
                o.positionOS = v.positionOS.xyz; // 传出模型空间坐标
                o.uv = v.uv;
                o.vertexColor = v.color;
                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normInputs.normalWS;
                o.tangentWS = float4(normInputs.tangentWS, v.tangentOS.w);
                o.screenPos = ComputeScreenPos(o.positionCS);
                return o;
            }

            half4 frag(Varyings i, bool frontFace : SV_IsFrontFace) : SV_Target {
                float2 screenUV = i.screenPos.xy / (i.screenPos.w + 0.0001);
                float3 normalWS = normalize(i.normalWS);
                normalWS = frontFace ? normalWS : -normalWS;
                float3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);

                float3 bitangentWS = cross(normalWS, i.tangentWS.xyz) * i.tangentWS.w;
                float3x3 worldToTangent = float3x3(i.tangentWS.xyz, bitangentWS, normalWS);
                float3 viewDirTS = mul(worldToTangent, viewDirWS);

                // 1. POM 视差偏移
                float2 offsetUV = ParallaxMapping(i.uv, viewDirTS);

                // 2. Normal Map
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv), _NormalScale);
                float3 perturbedNormalWS = normalize(mul(normalTS, worldToTangent));

                // 3. Base Color
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, offsetUV) * i.vertexColor;
                half3 mainColorRGB = texCol.rgb * _BaseColor.rgb * _MainTexIntensity;

                // --- 4. 修改点：静态局部空间内部纹理 ---
                // 直接使用局部空间坐标的 XZ 分量，不叠加视点方向，确保纹理固定在物体内部
                float2 internalUV = i.positionOS.xz * _InternalScale; 
                half3 finalInternal = SAMPLE_TEXTURE2D(_InternalTex, sampler_InternalTex, internalUV).rgb * _InternalColor.rgb * _InternalIntensity;

                // 5. Reflection
                float3 reflectDir = reflect(-viewDirWS, perturbedNormalWS);
                half3 reflection = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, reflectDir, _ReflectBlur * 7).rgb;
                reflection = clamp(reflection, 0.0, _ReflectHDRClamp);

                // 6. Fresnel
                float fresnel = pow(1.0 - saturate(dot(perturbedNormalWS, viewDirWS)), _FresnelPower);
                half3 finalFresnel = fresnel * _FresnelColor.rgb;

                // 7. Refraction (屏幕空间抓取)
                float2 refracOffset = perturbedNormalWS.xy * _RefractionStrength * _GlassEffectOpacity;
                half3 sceneColor = SampleSceneColor(screenUV + refracOffset).rgb;

                // Final Combine
                half3 combinedBase = lerp(sceneColor, mainColorRGB, _MainTexOpacity);
                half3 finalRGB = combinedBase + finalInternal + (reflection * _ReflectIntensity) + finalFresnel;
                
                return half4(finalRGB, _Opacity * texCol.a);
            }
            ENDHLSL
        }
    }
}