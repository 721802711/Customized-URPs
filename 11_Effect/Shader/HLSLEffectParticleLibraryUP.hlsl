/*
 Custom 参数的使用说明
 x：控制溶解
 y: 控制Mask标U方向偏移
 z: 控制Mask的V方向偏移
 w：控制整体亮度
*/

#ifndef  __EFFECT_PARTICLE_PASS_INCLUDED__
#define  __EFFECT_PARTICLE_PASS_INCLUDED__

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

//=========================================================属性========================================================================================

CBUFFER_START(UnityPerMaterial)

    float4 _MainTex_ST;
    float4 _DetailTex_ST;
    float4 _MaskTex_ST; 
    float4 _DistortTex_ST;
    float4 _DissolveTex_ST;
    float4 _SecondaryTex_ST;

    // 颜色
    half4 _Color;
    half4 _DetailColor;
    half4 _MaskTexColor;
    half4 _DissolveColor;
    half4 _RimColor;
    half4 _ChangeColor;

    half4 _PolarMainTiling; 
    half4 _PolarDetialTiling;

    half2 _MainTexWrap; // 控制主贴图 WrapMode (U,V)
    half _Alpha;
    half _Power;
    half _AorR;
    half _UVRot;
    half _SoftFade;
    half _UV2;

    // glow强度
    half _Glowintensity;
    half _UseCustomColor;

    // 副纹理
    float _SecondaryTex_Speed_U;
    float _SecondaryTex_Speed_V;

    // 边缘光
    half _RimPower;
    half _RimRevert;
    half _RimAlpha;

    // uv极坐标
    half _UV_Polar_Main;
    half _MainTexAngle;

    float _UseCustom2MainUV; // 控制是否使用 Custom2 作为主贴图 UV 偏移

    // uv速度
    float _UV_Speed_U_Main;
    float _UV_Speed_V_Main;

    half _UV_Polar_Detial;
    float _UV_Speed_U_Detail;
    float _UV_Speed_V_Detail;
    half _DetailTexAngle;
    half _DetailTexColorAdd;
    half _DetailTexColorLerp;
    half _DetailTexAlphaAdd;
    half _DetailTexAlphaLerp;
    half _UVRot_Detail;

    // --- 顶点动画新增 ---
    float4 _VertexAnimTex_ST;
    float _VertexAnimSpeed_U;
	float _VertexAnimSpeed_V;
    float _VertexAnimStrength;
    float _VertexAnimScale;
    float _VertexAnimSpeed; 

	float _VertexAnimAxis; // 0:X轴, 1:Y轴, 2:Z轴
	float _UseVertexAnimTex; // 控制是否开启顶点动画	

	float _VertexAnimPhaseAxis; // 0:X轴, 1:Y轴, 2:Z轴
	float _VertexAnimWeightUV; // 0:None, 1:U, 2:V


    // 遮罩
    float _UV_Speed_U_Mask;
    float _UV_Speed_V_Mask;
    half _MaskTexAngle;
    half2 _MaskTexWrap; // 控制遮罩贴图 WrapMode (U,V)

    half _UVRot_Mask;
    half _MaskTexAorR;
    half _MaskTexRotSpeed;
    half _MaskUvOffsetMain;
    half _MaskUvOffset;
    half _MaskOne_UV;
    half _MaskUV_one;

    float _speedU;
    float _speedV;

    half _MaskDistort;  // 控制遮罩是否开启扭曲
    half _MaskDistortStrength; // 遮罩扭曲强度

    // 扭曲
    half _DistortStrength;
    float _DistortTex_Speed_U;
    float _DistortTex_Speed_V;
    half _DistortTexStrengthAir;
    half _UVRot_DistortTex;
    half _DistortTexRotSpeed;
    half _MainVertStrength;
    half _MaskVertStrength;

    // 溶解基础
    half _DissolveStrength;
    half _DissolveWidth;
    half _DissolveAlpha;
    half _DissolveSmooth;
    half _DissolveDistort;
    float _Dissolve_Speed_U;
    float _Dissolve_Speed_V;

    // 定向溶解新增属性
    float4 _RampTex_ST;
    float _DissolveDir;     // 0:UP, 1:DOWN, 2:LEFT, 3:RIGHT
    float _MinBorder;
    float _MaxBorder;
    half _DistanceEffect;
    half _UseRamp;          // 关键字控制
    half _UseDirDissolve;   // 关键字控制

    half _UV_Speed_U_Main_Mirror;
    half _UV_Speed_V_Main_Mirror;

CBUFFER_END

TEXTURE2D(_CameraDepthTexture);        SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_MainTex);                   SAMPLER(sampler_MainTex); 
TEXTURE2D(_SecondaryTex);              SAMPLER(sampler_SecondaryTex); 
TEXTURE2D(_DetailTex);                 SAMPLER(sampler_DetailTex);
TEXTURE2D(_MaskTex);                   SAMPLER(sampler_MaskTex);
TEXTURE2D(_DistortTex);                SAMPLER(sampler_DistortTex);
TEXTURE2D(_DissolveTex);               SAMPLER(sampler_DissolveTex);
TEXTURE2D(_RampTex);                   SAMPLER(sampler_RampTex); // Ramp 贴图定义
TEXTURE2D(_VertexAnimTex);             SAMPLER(sampler_VertexAnimTex); // 顶点动画控制贴图

//===================================================== 函数 ================================================================================================

inline half2 UVSpeed(half speedU, half speedV)                           
{
    return _Time.y * half2(speedU, speedV);
}

inline half2 UVRotate(half2 uv, half angle)
{
    half cosuv = cos((PI / 180.0) * angle * 360);
    half sinuv = sin((PI / 180.0) * angle * 360);
    return mul(uv - half2(0.5, 0.5), half2x2(cosuv, -sinuv, sinuv, cosuv)) + half2(0.5, 0.5);
}

inline half2 UVPolar(half2 uv, half2 offset = 0, half radialScale = 1, half lengthScale = 1)
{
    float2 delta = uv - 0.5f + offset;
    float radius = length(delta) * 2 * radialScale;
    float angle = frac(atan2(delta.x, delta.y) * 1.0 / 6.28 * lengthScale);
    return float2(radius, angle);
}

//===================================================== 结构体 ================================================================================================

struct appdata
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float4 uv1 : TEXCOORD1;
    half4 color : COLOR;
    float4 texcoord1 : TEXCOORD2; 
    float4 custom2 : TEXCOORD3; 
#if _USE_RIM
    float3 normal : NORMAL;
#endif
};

struct v2f
{
#if _USE_DETAIL
    float4 uv : TEXCOORD0;
#else 
    float2 uv : TEXCOORD0;
#endif

    half4 color : COLOR;
    float4 vertex : SV_POSITION;

#if defined(_USE_SOFTPARTICLE)
    float4 projPos : TEXCOORD2;
#endif

#if _USE_SECONDARYTEX
    float2 uvSec : TEXCOORD1;
#endif

#if _USE_DISTORT
    float4 uv1 : TEXCOORD3;
#else
    float2 uv1 : TEXCOORD3;
#endif

#if _USE_DISSOLVE
    float2 uv2 : TEXCOORD6;
    float3 localPos : TEXCOORD9; // 传递本地位置
#endif

#if _USE_RIM
    float3 viewDir : TEXCOORD4;
    half3 normal : TEXCOORD5;
#endif
 
    float4 uv3 : TEXCOORD7;
    float4 custom2 : TEXCOORD8; 
};

//========================================================= 顶点着色器 ========================================================================================

v2f vert(appdata v)
{
    v2f o;

    float3 posOS = v.positionOS.xyz;

	// --- 顶点动画逻辑 ---
#if defined(_USE_VERTEX_ANIM)
	float finalMove = _VertexAnimStrength;
	float waveOffset = 0;

    if (_UseVertexAnimTex > 0.5)
    {

    // 1. UV 流动采样
    float2 animUV = TRANSFORM_TEX(v.uv, _VertexAnimTex) + float2(_VertexAnimSpeed_U, _VertexAnimSpeed_V) * _Time.y;
    float3 animRGB = SAMPLE_TEXTURE2D_LOD(_VertexAnimTex, sampler_VertexAnimTex, animUV, 0).rgb;

	// 2. 根据轴向选择位移方向


    if (_VertexAnimAxis == 0) 
        posOS.x += animRGB.r * finalMove;
    else if (_VertexAnimAxis == 1) 
        posOS.y += animRGB.g * finalMove;
    else 
        posOS.z += animRGB.b * finalMove;
	}
	else
	{
    // 3. 新增 Sin 曲线位移 (常驻或叠加)

    float spatialPhase = posOS.y; // 默认 Y
    if (_VertexAnimPhaseAxis == 0) spatialPhase = posOS.x;
    else if (_VertexAnimPhaseAxis == 2) spatialPhase = posOS.z;

    float weight = 1.0;
    if (_VertexAnimWeightUV == 1) weight = v.uv.x;
    else if (_VertexAnimWeightUV == 2) weight = v.uv.y;

    waveOffset = sin(spatialPhase * _VertexAnimScale + _Time.y * _VertexAnimSpeed) * finalMove * weight;

    if (_VertexAnimAxis == 0) 
        posOS.x += waveOffset;
    else if (_VertexAnimAxis == 1) 
        posOS.y += waveOffset;
    else 
        posOS.z += waveOffset;
	}
#endif


    o.vertex = TransformObjectToHClip(posOS);
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.color = v.color;
    o.uv3 = v.texcoord1;
    o.custom2 = v.custom2;

    if (_UVRot != 0) o.uv.xy = UVRotate(o.uv.xy, _MainTexAngle);

#if _USE_DETAIL
    o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
    if (_UVRot_Detail != 0) o.uv.zw = UVRotate(o.uv.zw, _DetailTexAngle);
#endif

#if _USE_MASK
    o.uv1.xy = TRANSFORM_TEX(v.uv, _MaskTex);
    half2 uvMaskSpeed = UVSpeed(_UV_Speed_U_Mask, _UV_Speed_V_Mask);
    half2 maskUV_One = lerp(half2(_speedU, _speedV), half2(o.uv3.y, o.uv3.z), _MaskOne_UV);
    half2 maskUV = lerp(uvMaskSpeed, maskUV_One, _MaskUV_one);

    if (_UVRot_Mask != 0)
    {
        o.uv1.xy = UVRotate(o.uv1.xy, _MaskTexAngle + _MaskTexRotSpeed * _Time.y) + uvMaskSpeed;
    }
    else o.uv1.xy += maskUV;

    if (_MaskUvOffsetMain != 0) o.uv1.x += v.uv1.x * _MaskUvOffset;
    if (_MaskTexWrap.x > 0.5) o.uv1.x = clamp(o.uv1.x, 0.0, 1.0);
    if (_MaskTexWrap.y > 0.5) o.uv1.y = clamp(o.uv1.y, 0.0, 1.0);
#endif

#if _USE_SECONDARYTEX
    o.uvSec = TRANSFORM_TEX(v.uv, _SecondaryTex) + UVSpeed(_SecondaryTex_Speed_U, _SecondaryTex_Speed_V);
#endif

#if _USE_DISTORT
    half2 uvDistortSpeed = UVSpeed(_DistortTex_Speed_U, _DistortTex_Speed_V);
#if _USE_MASK
    o.uv1.zw = TRANSFORM_TEX(v.uv, _DistortTex);
    if (_UVRot_DistortTex != 0) o.uv1.zw = uvDistortSpeed + UVRotate(o.uv1.zw, _DistortTexRotSpeed * _Time.y);
    else o.uv1.zw += uvDistortSpeed;
#else
    o.uv1.xy = TRANSFORM_TEX(v.uv, _DistortTex);
    if (_UVRot_DistortTex != 0) o.uv1.xy = uvDistortSpeed + UVRotate(o.uv1.xy, _DistortTexRotSpeed * _Time.y);
    else o.uv1.xy += uvDistortSpeed;
#endif
#endif

#if _USE_RIM
    o.viewDir = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(v.positionOS.xyz));
    o.normal = TransformObjectToWorldNormal(v.normal.xyz, true);
#endif

#if _USE_DISSOLVE
    o.uv2.xy = TRANSFORM_TEX(v.uv, _DissolveTex);
    o.localPos = posOS; // 记录本地坐标
#endif

#if (defined(_USE_SOFTPARTICLE))
    o.projPos = ComputeScreenPos(o.vertex);
#endif

    return o;
}

//========================================================= 片元着色器 ========================================================================================

half4 frag(v2f i , half4 color)
{
    float2 mainUV = i.uv.xy;
    if (_UV_Polar_Main > 0) mainUV = UVPolar(mainUV, _PolarMainTiling.zw, _PolarMainTiling.x, _PolarMainTiling.y);

#if defined(_USE_CUSTOM2_MAINUV)
    mainUV += i.custom2.xy;
#else
    half2 uvMainSpeed = UVSpeed(_UV_Speed_U_Main, _UV_Speed_V_Main);
    uvMainSpeed.x = lerp(uvMainSpeed.x, -uvMainSpeed.x, _UV_Speed_U_Main_Mirror);
    uvMainSpeed.y = lerp(uvMainSpeed.y, -uvMainSpeed.y, _UV_Speed_V_Main_Mirror);
    mainUV += uvMainSpeed;
#endif

    half distort = 0;
#if _USE_DISTORT
#if _USE_MASK
    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv1.zw);
#else
    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv1.xy);
#endif
    distort = distortTex.a * distortTex.r;
    mainUV += distort * _DistortStrength;
#endif

    if (_MainTexWrap.x > 0.5) mainUV.x = clamp(mainUV.x, 0, 1);
    if (_MainTexWrap.y > 0.5) mainUV.y = clamp(mainUV.y, 0, 1);

    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);

#if defined(_MAINTEX_CHANNEL_R)
    col = half4(col.r, col.r, col.r, col.a);
#elif defined(_MAINTEX_CHANNEL_G)
    col = half4(col.g, col.g, col.g, col.a);
#elif defined(_MAINTEX_CHANNEL_B)
    col = half4(col.b, col.b, col.b, col.a);
#elif defined(_MAINTEX_CHANNEL_A)
    col = half4(col.a, col.a, col.a, col.a);
#endif

#if _USE_SECONDARYTEX
    col *= SAMPLE_TEXTURE2D(_SecondaryTex, sampler_SecondaryTex, i.uvSec);
#endif

#if _USE_DETAIL
    if (_UV_Polar_Detial > 0) i.uv.zw = UVPolar(i.uv.zw, _PolarDetialTiling.zw, _PolarDetialTiling.x, _PolarDetialTiling.y);
    i.uv.zw += UVSpeed(_UV_Speed_U_Detail, _UV_Speed_V_Detail);
    half4 detail = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv.zw + distort * _DistortStrength) * _DetailColor;
    col.rgb = lerp(col.rgb + detail.rgb * _DetailTexColorAdd, detail.rgb, _DetailTexColorLerp);
    col.a = lerp(col.a + detail.a * _DetailTexAlphaAdd, detail.a, _DetailTexAlphaLerp);
#endif

    float tex_r = col.r;
    col = col * color * i.color;
    col.a = saturate(lerp(col.a, tex_r, _AorR) * _Alpha * i.color.a);

#if _USE_RIM
    half rim = pow(1.0 - saturate(dot(i.viewDir, i.normal)), _RimPower);
    if (_RimRevert > 0) rim = 1 - rim;
    col.rgb += (_RimColor * rim).rgb;
    if (_RimAlpha > 0) col.a *= rim;
#endif

// 定向溶解逻辑整合
#if _USE_DISSOLVE
    float2 dissolveUV = i.uv2.xy + UVSpeed(_Dissolve_Speed_U, _Dissolve_Speed_V) + i.uv3.yz;
    if (_DissolveDistort > 0) dissolveUV += distort * _DistortStrength;
    half noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
    
    float finalCutout = noise;

    #if defined(_USE_DIR_DISSOLVE)
        float range = _MaxBorder - _MinBorder;
        float invRange = 1.0 / max(range, 0.0001);
        float currentPos = 0;
        float border = _MinBorder;
        // 0:UP(Y+), 1:DOWN(Y-), 2:LEFT(X-), 3:RIGHT(X+)
        if (_DissolveDir == 0) { currentPos = i.localPos.y; border = _MaxBorder; }
        else if (_DissolveDir == 1) { currentPos = i.localPos.y; border = _MinBorder; }
        else if (_DissolveDir == 2) { currentPos = i.localPos.x; border = _MinBorder; }
        else { currentPos = i.localPos.x; border = _MaxBorder; }
        float dist = abs(currentPos - border);
        float normalizedDist = saturate(dist * invRange);
        finalCutout = lerp(noise, normalizedDist, _DistanceEffect);
    #endif

    half dissAmount = saturate(lerp(_DissolveStrength, i.uv3.x, _DissolveAlpha));
    clip(finalCutout - dissAmount);

    #if defined(_USE_RAMP)
        float degree = saturate((finalCutout - dissAmount) / max(_DissolveWidth, 0.001));
        half4 rampColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, 0.5));
        col.rgb = lerp(rampColor.rgb * _DissolveColor.rgb, col.rgb, degree);
    #else
        // 原有步进式边缘颜色逻辑
        half t = smoothstep(0, _DissolveSmooth, saturate(finalCutout - dissAmount));
        half width = step(t + _DissolveWidth, _DissolveSmooth);
        half Dissolve = step(t, _DissolveSmooth);
        col.rgb += (Dissolve - width) * _DissolveColor.rgb;
        col.a *= t;
    #endif
#endif

#if _USE_MASK
    half2 maskUV = i.uv1.xy;
    if (_MaskDistort > 0) maskUV += distort * _MaskDistortStrength;
    half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskUV);
    #if defined(_MASKTEX_CHANNEL_R)
        mask = mask.rrrr;
    #elif defined(_MASKTEX_CHANNEL_G)
        mask = mask.gggg;
    #elif defined(_MASKTEX_CHANNEL_B)
        mask = mask.bbbb;
    #elif defined(_MASKTEX_CHANNEL_A)
        mask = mask.aaaa;
    #endif
    col *= mask * _MaskTexColor;
    col.a *= lerp(mask.r, mask.a, _MaskTexAorR);
#endif

#if _USE_SOFTPARTICLE
    float2 screenPos = i.projPos.xy / i.projPos.w;
    float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
    float eyeZ = LinearEyeDepth(sceneZ, _ZBufferParams);
    col.a *= saturate((eyeZ - i.projPos.w) / _SoftFade);
#endif

#if _USE_CHANGECOLOR
    col.rgb = _ChangeColor.rgb * ((col.r + col.g + col.b) / 3.0);
#endif

    return pow(abs(col), _Power);
}

half4 fragFront(v2f i) : SV_Target
{
    half4 customColor = _Color * _Glowintensity * i.uv3.w;
    return frag(i, lerp(_Color * _Glowintensity, customColor, _UseCustomColor));
}

#endif