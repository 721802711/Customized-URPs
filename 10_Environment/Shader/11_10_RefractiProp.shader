Shader "B/11_10_RefractiProp"
{
    Properties
    {
        [Header(Render State)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 0

        [Header(Base Settings)]
        _MainTex ("Base Texture", 2D) = "white" {}
        _MainTexIntensity ("MainTex Color Strength", Range(0, 2)) = 1.0 
        _MainTexOpacity ("MainTex Opacity", Range(0, 1)) = 1.0 
        [HDR]_BaseColor ("Base Color Tint", Color) = (1,1,1,1)

        [Header(Overlay Texture)] // 新增：纹理叠加部分
        _OverlayTex ("Overlay Texture", 2D) = "white" {}
        [HDR]_OverlayColor ("Overlay Color", Color) = (1,1,1,1)
        _OverlayIntensity ("Overlay Intensity", Range(0, 5)) = 0.0 // 默认为0，不叠加

        [Header(Glass and Effects)]
        _GlassEffectOpacity ("Glass Effect Opacity", Range(0, 1)) = 1.0 
        _Opacity ("Global Alpha", Range(0,1)) = 1.0 

        [Header(Normal Map)]
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Intensity", Range(0, 2)) = 1.0

        [Header(Reflection and Specular)]
        [NoScaleOffset]_ReflectionCube ("Reflection Cube", CUBE) = "" {}
        _ReflectBlur ("Reflect Blur (LOD)", Range(0, 1)) = 0
        _ReflectIntensity ("Reflect Intensity", Range(0, 5)) = 1.0
        _ReflectHDRClamp ("Reflect HDR Clamp", Float) = 10.0
        [HDR]_SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularIntensity ("Specular Intensity", Range(0, 5)) = 1.0 
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5 

        [Header(Fresnel)]
        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 5.0 

        [Header(Refraction)]
        _RefractionStrength ("Refraction Strength", Range(0, 0.1)) = 0.02
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Name "ForwardLit"
            
            Cull [_Cull]      
            ZWrite Off    
            Blend SrcAlpha OneMinusSrcAlpha 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _OverlayTex_ST; // 叠加纹理的 ST
                float4 _NormalMap_ST;
                half4  _BaseColor;
                half   _MainTexIntensity;
                half   _MainTexOpacity;
                half4  _OverlayColor;
                half   _OverlayIntensity;
                half   _GlassEffectOpacity;
                half   _Opacity;
                half   _ReflectBlur;
                half   _ReflectIntensity;
                half   _ReflectHDRClamp;
                half4  _SpecularColor;    
                half   _SpecularIntensity;
                half   _Smoothness;
                half4  _FresnelColor;
                half   _FresnelPower;
                half   _NormalScale;
                half   _RefractionStrength;
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);
            TEXTURE2D(_OverlayTex);       SAMPLER(sampler_OverlayTex); // 叠加纹理采样器
            TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
            TEXTURECUBE(_ReflectionCube); SAMPLER(sampler_ReflectionCube);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                half4  color      : COLOR; 
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float2 overlayUV  : TEXCOORD6; // 增加独立 UV 槽位
                float3 normalWS   : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 tangentWS  : TEXCOORD3; 
                float4 screenPos  : TEXCOORD4;
                half4  vertexColor: TEXCOORD5;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;
                o.uv = v.uv;
                o.overlayUV = TRANSFORM_TEX(v.uv, _OverlayTex); // 处理叠加纹理的 Tiling/Offset
                o.vertexColor = v.color;

                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normInputs.normalWS;
                o.tangentWS = float4(normInputs.tangentWS, v.tangentOS.w);
                
                o.screenPos = ComputeScreenPos(o.positionCS);
                return o;
            }

            half4 frag(Varyings i, bool frontFace : SV_IsFrontFace) : SV_Target
            {
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // 1. 双面法线逻辑
                float3 normalWS = normalize(i.normalWS);
                normalWS = frontFace ? normalWS : -normalWS; 
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);

                // TBN 扰动
                float2 normUV = TRANSFORM_TEX(i.uv, _NormalMap);
                float3 bitangentWS = cross(normalWS, i.tangentWS.xyz) * i.tangentWS.w;
                float3x3 TBN = float3x3(i.tangentWS.xyz, bitangentWS, normalWS);
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normUV), _NormalScale);
                float3 perturbedNormalWS = normalize(mul(normalTS, TBN));

                // 2. 基础色采样
                float2 mainUV = TRANSFORM_TEX(i.uv, _MainTex);
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);
                half3 mainColorRGB = texCol.rgb * _BaseColor.rgb * _MainTexIntensity;

                // 3. 叠加纹理逻辑 (Multiply 叠加模式)
                half4 overlayCol = SAMPLE_TEXTURE2D(_OverlayTex, sampler_OverlayTex, i.overlayUV);
                half3 finalBaseColor = mainColorRGB * lerp(1.0, overlayCol.rgb * _OverlayColor.rgb, _OverlayIntensity);
                
                // 结合顶点颜色
                finalBaseColor *= i.vertexColor.rgb;

                Light mainLight = GetMainLight();

                // 4. Specular (高光)
                float3 halfDir = normalize(mainLight.direction + viewDirWS);
                float spec = pow(saturate(dot(perturbedNormalWS, halfDir)), _Smoothness * 128.0) * _SpecularIntensity;
                half3 finalSpecular = mainLight.color * _SpecularColor.rgb * spec * _GlassEffectOpacity;

                // 5. Fresnel (边缘光)
                float fresnel = pow(1.0 - saturate(dot(perturbedNormalWS, viewDirWS)), _FresnelPower);
                half3 finalFresnel = fresnel * _FresnelColor.rgb * _GlassEffectOpacity;

                // 6. Reflection (环境反射)
                float3 reflectDir = reflect(-viewDirWS, perturbedNormalWS);
                float lod = _ReflectBlur * 7.0; 
                half3 reflection = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, reflectDir, lod).rgb;
                reflection = clamp(reflection, 0.0, _ReflectHDRClamp); 
                half3 finalReflection = reflection * _ReflectIntensity * _GlassEffectOpacity;

                // 7. Refraction (背景折射)
                float2 refractionOffset = perturbedNormalWS.xy * _RefractionStrength * _GlassEffectOpacity;
                half3 sceneColor = SampleSceneColor(screenUV + refractionOffset).rgb;

                // 8. 最终合成
                half3 combinedBase = lerp(sceneColor, finalBaseColor, _MainTexOpacity);
                half3 finalRGB = combinedBase + finalReflection + finalSpecular + finalFresnel;
                
                // Alpha 计算
                half finalAlpha = texCol.a * _BaseColor.a * _Opacity * i.vertexColor.a;

                return half4(finalRGB, finalAlpha);
            }
            ENDHLSL
        }
    }
}