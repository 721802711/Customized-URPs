#ifndef PBR_COMMON_INCLUDED
#define PBR_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  

//C缓存区
CBUFFER_START(UnityPerMaterial)
float4 _DiffuseTex_ST;
float4 _BaseColor,_EmissivColor;
float _NormalScale,_Metallic,_Roughness,_EmissivInt,_LightInt;
float _NormalInvertG,_RoughnessInvert,_AO;
CBUFFER_END

// 贴图
TEXTURE2D(_DiffuseTex);                         SAMPLER(sampler_DiffuseTex);
TEXTURE2D(_NormalTex);                         SAMPLER(sampler_NormalTex);
TEXTURE2D(_MaskTex);                         SAMPLER(sampler_MaskTex);

#endif