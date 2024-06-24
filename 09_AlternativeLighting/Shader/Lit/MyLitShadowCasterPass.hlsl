#ifndef MY_LIT_SHADOW_CASTER_PASS_INCLUDED
#define MY_LIT_SHADOW_CASTER_PASS_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  
#include "Lit/MyLitCommon.hlsl"

struct Attributes                         // 输入结构体
{
    float3 positionOS : POSITION;           //  输入顶点信息
    float3 normalOS : NORMAL;               //  输入法线信息
#ifdef _ALPHA_CUTOUT
    float2 uv : TEXCOORD0;
#endif
};

struct Interpolators
{
    float4 positionCS : SV_POSITION;
#ifdef _ALPHA_CUTOUT
    float2 uv : TEXCOORD0;
#endif
};

float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS)
{
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
    return normalWS * (dot(normalWS, viewDirWS) < 0 ? -1 : 1);
}

float3 _LightDirection;

float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS)
{
    float3 lightDirectionWS = _LightDirection;

#ifdef _DOUBLE_SIDED_NORMALS
    normalWS = FlipNormalBasedOnViewDir(normalWS, positionWS);
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif


return positionCS;
}


Interpolators vert(Attributes input)
{
    Interpolators output;      // 声明变量

    VertexPositionInputs  PositionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs    normInputs     = GetVertexNormalInputs(input.normalOS);   // 转换空间   

    output.positionCS = GetShadowCasterPositionCS(PositionInputs.positionWS, normInputs.normalWS);

#ifdef _ALPHA_CUTOUT
    output.uv =  TRANSFORM_TEX(input.uv, _ColorMap);
#endif

    return output;             // 输出
}

float4 frag(Interpolators input) : SV_TARGET 
{

#ifdef _ALPHA_CUTOUT
    float2 uv = input.uv;
    float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
    TestAlphaClip(colorSample);
#endif
    return 0;
}

#endif