#ifndef MY_LIT_COMMON_INCLUDED
#define MY_LIT_COMMON_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  

float4 _ColorTint;
float4 _ColorMap_ST;
float4 _EmissionTint;
float3 _SpecularTint;
float _Smoothness;
float _NormalStrength;
float _Metalness;
float _ParallaxStrength;
float _CutOff;
float _ClearCoatStrength;
float _ClearCoatSmoothness;

TEXTURE2D(_ColorMap);     SAMPLER(sampler_ColorMap);
TEXTURE2D(_NormalMap);     SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetalnessMask);     SAMPLER(sampler_MetalnessMask);
TEXTURE2D(_SpecularMap);     SAMPLER(sampler_SpecularMap);
TEXTURE2D(_SmoothnessMask);     SAMPLER(sampler_SmoothnessMask);
TEXTURE2D(_EmissionMap);     SAMPLER(sampler_EmissionMap);
TEXTURE2D(_ParallaxMap);     SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_ClearCoatMask);     SAMPLER(sampler_ClearCoatMask);
TEXTURE2D(_ClearCoatSmoothnessMask);     SAMPLER(sampler_ClearCoatSmoothnessMask);



void TestAlphaClip(float4 colorSampe)
{
#if _ALPHA_CUTOUT
    clip(colorSampe.a * _ColorTint.a - _CutOff);
#endif
} 

#endif