#ifndef MLIBRARY_REFRACTION_INCLUDED
#define MLIBRARY_REFRACTION_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
TEXTURECUBE(_ReflectionCube); SAMPLER(sampler_ReflectionCube);

CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST;
    float4 _NormalMap_ST;
    half4  _BaseColor;
    half   _MainTexIntensity;
    half   _MainTexOpacity;
    half   _GlassEffectOpacity; // 新增：控制反射和折射的总强度
    half   _Opacity;
    half   _ReflectBlur;
    half   _ReflectIntensity;
    half   _NormalScale;
    half   _RefractionStrength;
CBUFFER_END

struct appdata
{
    float4 positionOS : POSITION;
    float2 uv         : TEXCOORD0;
    float3 normalOS   : NORMAL;
    float4 tangentOS  : TANGENT;
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float2 uv         : TEXCOORD0;
    float3 normalWS   : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float4 tangentWS  : TEXCOORD3; 
    float4 screenPos  : TEXCOORD4;
};

v2f vert(appdata v)
{
    v2f o;
    VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = posInputs.positionCS;
    o.positionWS = posInputs.positionWS;
    o.uv = v.uv;

    VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
    o.normalWS = normInputs.normalWS;
    o.tangentWS = float4(normInputs.tangentWS, v.tangentOS.w);
    
    o.screenPos = ComputeScreenPos(o.positionCS);
    return o;
}

half4 frag(v2f i, bool frontFace : SV_IsFrontFace) : SV_Target
{
    // 1. 双面法线准备
    float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
    float3 normalWS = normalize(i.normalWS);
    normalWS = frontFace ? normalWS : -normalWS;

    // 2. TBN 法线扰动
    float2 normalUV = TRANSFORM_TEX(i.uv, _NormalMap);
    float3 bitangentWS = cross(normalWS, i.tangentWS.xyz) * i.tangentWS.w;
    float3x3 TBN = float3x3(i.tangentWS.xyz, bitangentWS, normalWS);
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV), _NormalScale);
    float3 perturbedNormalWS = normalize(mul(normalTS, TBN));

    // 3. 主贴图颜色计算
    float2 mainUV = TRANSFORM_TEX(i.uv, _MainTex);
    half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);
    half3 mainColorRGB = texCol.rgb * _BaseColor.rgb * _MainTexIntensity;

    // 4. 反射计算 (受 _GlassEffectOpacity 控制)
    float3 reflectDir = reflect(-viewDirWS, perturbedNormalWS);
    float lod = _ReflectBlur * 7.0; 
    half3 reflection = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, reflectDir, lod).rgb;
    half3 finalReflection = reflection * _ReflectIntensity * _GlassEffectOpacity;

    // 5. 折射计算 (受 _GlassEffectOpacity 控制)
    float2 screenUV = i.screenPos.xy / i.screenPos.w;
    // 只有当玻璃效果透明度开启时，才应用法线偏移
    float2 refractionOffset = perturbedNormalWS.xy * _RefractionStrength * _GlassEffectOpacity;
    half3 sceneColor = SampleSceneColor(screenUV + refractionOffset).rgb;
    
    // 如果 _GlassEffectOpacity 为 0，物体背后完全透明（显示原始场景颜色）
    // 如果为 1，则完全受折射偏移影响
    half3 finalRefraction = sceneColor; 

    // 6. 最终混合逻辑
    // A. 先计算贴图与背景(折射)的混合
    half3 combinedBase = lerp(finalRefraction, mainColorRGB, _MainTexOpacity);
    
    // B. 叠加反射效果
    half3 finalRGB = combinedBase + finalReflection;
    
    // C. 最终 Alpha 控制
    half finalAlpha = texCol.a * _BaseColor.a * _Opacity;

    return half4(finalRGB, finalAlpha);
}

#endif