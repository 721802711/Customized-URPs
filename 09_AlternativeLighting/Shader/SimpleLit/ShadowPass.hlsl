#ifndef SHADOW_PASS_INCLUDED
#define SHADOW_PASS_INCLUDED



struct Attributes
{
    float4 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    float2 texcoord      : TEXCOORD0;   // 纹理坐标
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
};


float3 _LightDirection;
float3 _LightPosition;


float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    return positionCS;
}

Varyings vert(Attributes input)
{
    Varyings output;
        output.uv = TRANSFORM_TEX(input.texcoord, _MainTex); 
        output.positionCS = GetShadowPositionHClip(input);
    return output;
}

real4 frag(Varyings input): SV_TARGET
{

    half AlphaTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv).a;    //获取贴图的Alpha
    clip(AlphaTex - _CutOff);
    return 0;
}

#endif
