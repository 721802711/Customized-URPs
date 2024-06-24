#ifndef PBR_SHADOW_CASTER_PASS_INCLUDED
#define PBR_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  
#include "PBR_Common.hlsl"

struct appdata
{
    float4 positionOS : POSITION;                     //输入顶点
    float4 normalOS : NORMAL;                         //输入法线
    float2 texcoord : TEXCOORD0;                      //输入uv信息
};

struct v2f
{
    float2 uv : TEXCOORD0;                            //输出uv
    float4 positionCS : SV_POSITION;                  //齐次位置
};

v2f vertshadow(appdata v)
{
    v2f o;
    float3 posWS = TransformObjectToWorld(v.positionOS.xyz);         //世界空间下顶点位置
    float3 norWS = TransformObjectToWorldNormal(v.normalOS.xyz);           //世界空间下顶点位置
    Light MainLight = GetMainLight();                                     //获取灯光

    o.positionCS = TransformWorldToHClip(ApplyShadowBias(posWS,norWS,MainLight.direction));             //这里是公共结构体里调用就可以
    #if UNITY_REVERSED_Z
    o.positionCS.z - min(o.positionCS.z,o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    o.positionCS.z - max(o.positionCS.z,o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return o;
}
float4 fragshadow(v2f i) : SV_Target
{

    return 0;
}



#endif