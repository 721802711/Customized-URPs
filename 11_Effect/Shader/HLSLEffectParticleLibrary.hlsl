/*
 Custom 参数的使用说明
 x：控制溶解
 y: 控制Mask的U方向偏移
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

	half2 _MainTexWrap; // 新增变量，控制主贴图 WrapMode (U,V)
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



	//边缘光

	half _RimPower;
	half _RimRevert;
	half _RimAlpha;

	// uv极坐标
	half _UV_Polar_Main;
	half _MainTexAngle;


	float _UseCustom2MainUV; // 新增变量，控制是否使用 Custom2 作为主贴图 UV 偏移

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
	

	// 遮罩
	float _UV_Speed_U_Mask;
	float _UV_Speed_V_Mask;
	half _MaskTexAngle;

	half2 _MaskTexWrap; // 新增变量，控制遮罩贴图 WrapMode (U,V)


	half _UVRot_Mask;
	half _MaskTexAorR;
	half _MaskTexRotSpeed;
	half _MaskUvOffsetMain;
	half _MaskUvOffset;
	half _MaskOne_UV;
	half _MaskUV_one;

	float _speedU;
	float _speedV;

	half _MaskDistort;  // 新增变量，控制遮罩是否开启扭曲
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

	half _DissolveStrength;
	half _DissolveWidth;
	half _DissolveAlpha;
	half _DissolveSmooth;
	half _DissolveDistort;


	float _Dissolve_Speed_U;
	float _Dissolve_Speed_V;


	half _UV_Speed_U_Main_Mirror;
	half _UV_Speed_V_Main_Mirror;

CBUFFER_END

TEXTURE2D(_CameraDepthTexture);            SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_MainTex);                       SAMPLER(sampler_MainTex); // 主纹理
TEXTURE2D(_SecondaryTex);                  SAMPLER(sampler_SecondaryTex); // 副纹理
TEXTURE2D(_DetailTex);                     SAMPLER(sampler_DetailTex);
TEXTURE2D(_MaskTex);                       SAMPLER(sampler_MaskTex);
TEXTURE2D(_DistortTex);                    SAMPLER(sampler_DistortTex);
TEXTURE2D(_DissolveTex);                   SAMPLER(sampler_DissolveTex);




//=====================================================   函数 ================================================================================================


//uv速度计算
inline half2 UVSpeed(half speedU, half speedV)                           
{
	half2 uvSpeed = _Time.y * (half2(speedU, speedV));
	return uvSpeed;
}




inline half2 UVRotate(half2 uv, half angle)
{
    half cosuv = cos((PI / 180.0) * angle * 360);
    half sinuv = sin((PI / 180.0) * angle * 360);
    half2 uvRot = mul(uv - half2(0.5, 0.5), half2x2(cosuv, -sinuv, sinuv, cosuv)) + half2(0.5, 0.5);

	return uvRot;
}

// polar coordinates
inline half2 UVPolar(half2 uv, half2 offset = 0, half radialScale = 1, half lengthScale = 1)
{
	float2 delta = uv - 0.5f + offset;
	float radius = length(delta) * 2 * radialScale;
	float angle = frac(atan2(delta.x, delta.y) * 1.0 / 6.28 * lengthScale);
	float2 Out = float2(radius, angle);

	return Out;
}
//=====================================================   结构体 ================================================================================================

//顶点着色器
struct appdata
{
	float4 positionOS : POSITION;
	float2 uv : TEXCOORD0;
	// 遮罩UV偏移取值(x轴)
	float4 uv1 : TEXCOORD1;
	half4 color : COLOR;
    float4 texcoord1 : TEXCOORD2;                     //定义使用custom变量
	float4 custom2 : TEXCOORD3;                     //定义使用custom2变量
#if _USE_RIM
	float3 normal : NORMAL;
#endif

};

//片元结构体
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
    float2 uvSec : TEXCOORD1; // SecondaryTex 独立 UV 通道
#endif

#if _USE_DISTORT
    // uv1: mask 用或 distort 用
    float4 uv1 : TEXCOORD3;
#else
    float2 uv1 : TEXCOORD3;
#endif

#if _USE_DISSOLVE
    float2 uv2 : TEXCOORD6;
#endif

#if _USE_RIM
    float3 viewDir : TEXCOORD4;
    half3 normal : TEXCOORD5;
#endif

	//  始终定义 uv3，无论是否使用 mask 或 dissolve
    float4 uv3 : TEXCOORD7;
	
	float4 custom2 : TEXCOORD8; // 传递 custom2 变量
	
};



//=========================================================   顶点着色器 ========================================================================================
v2f vert(appdata v)
{
	v2f o;

	o.vertex = TransformObjectToHClip(v.positionOS.xyz);
	o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	o.color = v.color;

	o.uv3 = v.texcoord1;

	o.custom2 = v.custom2;   // 传给片元

	if (_UVRot != 0)
	{
		half2 uvRot = UVRotate(o.uv.xy, _MainTexAngle);
		o.uv.xy = uvRot;
	}

	// detial
#if _USE_DETAIL
	o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

	if (_UVRot_Detail != 0)
	{
		half2 uvDetailRot = UVRotate(o.uv.zw, _DetailTexAngle);
		o.uv.zw = uvDetailRot;
	}

#endif

// mask
#if _USE_MASK
    // 基础 UV
    o.uv1.xy = TRANSFORM_TEX(v.uv, _MaskTex);
    o.uv3 = v.texcoord1;

    // UV 移动速度
    half2 uvMaskSpeed = UVSpeed(_UV_Speed_U_Mask, _UV_Speed_V_Mask);

    // 一次性模式（Custom Y 控制）
    half2 oneMaskUV       = half2(_speedU, _speedV);
    half2 oneMaskCustomUV = half2(o.uv3.y, o.uv3.z);
    half2 maskUV_One      = lerp(oneMaskUV, oneMaskCustomUV, _MaskOne_UV);

    // 在循环模式和一次性模式之间切换
    half2 maskUV = lerp(uvMaskSpeed, maskUV_One, _MaskUV_one);

    // UV 旋转
    if (_UVRot_Mask != 0)
    {
        half2 uvMaskRot = UVRotate(o.uv1.xy, _MaskTexAngle + _MaskTexRotSpeed * _Time.y);
        o.uv1.xy = uvMaskRot + uvMaskSpeed;
    }
    else
    {
        o.uv1.xy += maskUV;
    }

    // UV 偏移
    if (_MaskUvOffsetMain != 0)
    {
        o.uv1.x += v.uv1.x * _MaskUvOffset;
    }

    // WrapMode (仅 Shader 内部做 Clamp，不影响 Import 设置)
    if (_MaskTexWrap.x > 0.5) o.uv1.x = clamp(o.uv1.x, 0.0, 1.0); // U
    if (_MaskTexWrap.y > 0.5) o.uv1.y = clamp(o.uv1.y, 0.0, 1.0); // V
#endif


	// 副纹理

#if _USE_SECONDARYTEX
	o.uvSec = TRANSFORM_TEX(v.uv, _SecondaryTex);
	o.uvSec += UVSpeed(_SecondaryTex_Speed_U, _SecondaryTex_Speed_V);
#endif



	// distort
#if _USE_DISTORT
	half2 uvDistortSpeed = UVSpeed(_DistortTex_Speed_U, _DistortTex_Speed_V);
	half2 uDistortRot = 0;

#if _USE_MASK
	o.uv1.zw = TRANSFORM_TEX(v.uv, _DistortTex);

	if (_UVRot_DistortTex != 0)
	{
		uDistortRot = UVRotate(o.uv1.zw, _DistortTexRotSpeed * _Time.y);
		o.uv1.zw = uvDistortSpeed + uDistortRot;
	}
	else
		o.uv1.zw += uvDistortSpeed;
#else
	o.uv1.xy = TRANSFORM_TEX(v.uv, _DistortTex);
	if (_UVRot_DistortTex != 0)
	{
		uDistortRot = UVRotate(o.uv1.xy, _DistortTexRotSpeed * _Time.y);
		o.uv1.xy = uvDistortSpeed + uDistortRot;
	}
	else
	{
		o.uv1.xy += uvDistortSpeed;
	}
#endif
#endif

	// rim
#if _USE_RIM

	o.viewDir = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(v.positionOS.xyz));
	o.normal = TransformObjectToWorldNormal(v.normal.xyz,true);

#endif

	// dissolve
#if _USE_DISSOLVE
	o.uv2.xy = TRANSFORM_TEX(v.uv, _DissolveTex);
	o.uv3 = v.texcoord1;
#endif

#if (defined(_USE_SOFTPARTICLE))
	o.projPos = ComputeScreenPos(o.vertex);
#endif

	// UNITY_TRANSFER_FOG(o, o.vertex);

	return o;
}


//=========================================================   片元着色器 ========================================================================================

half4 frag(v2f i , half4 color)
{
    float2 mainUV = i.uv;

    // 极坐标 UV 转换
    if (_UV_Polar_Main > 0)
    {
        mainUV = UVPolar(mainUV, _PolarMainTiling.zw, _PolarMainTiling.x, _PolarMainTiling.y);
    }

    // Custom2 或者 UVSpeed 偏移
    #if defined(_USE_CUSTOM2_MAINUV)
        // 使用 Custom2.xy 控制主纹理UV
        mainUV += i.custom2.xy;
    #else
        // 默认循环 UV 偏移
        half2 uvMainSpeed = UVSpeed(_UV_Speed_U_Main, _UV_Speed_V_Main);
        uvMainSpeed.x = lerp(uvMainSpeed.x, -uvMainSpeed.x, _UV_Speed_U_Main_Mirror);
        uvMainSpeed.y = lerp(uvMainSpeed.y, -uvMainSpeed.y, _UV_Speed_V_Main_Mirror);
        mainUV += uvMainSpeed;
    #endif

    //Distort 扰动
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

    // 4. WrapMode 控制（仅 Shader 内部做 Clamp，不改贴图设置）
    if (_MainTexWrap.x > 0.5) mainUV.x = clamp(mainUV.x, 0, 1);
    if (_MainTexWrap.y > 0.5) mainUV.y = clamp(mainUV.y, 0, 1);


    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);

    // 主贴图通道关键字控制（使用 multi_compile 定义的关键字）
    #if defined(_MAINTEX_CHANNEL_R)
        col = half4(col.r, col.r, col.r, col.a);
    #elif defined(_MAINTEX_CHANNEL_G)
        col = half4(col.g, col.g, col.g, col.a);
    #elif defined(_MAINTEX_CHANNEL_B)
        col = half4(col.b, col.b, col.b, col.a);
    #elif defined(_MAINTEX_CHANNEL_A)
        col = half4(col.a, col.a, col.a, col.a);
    #elif defined(_MAINTEX_CHANNEL_ALL)
        
		col = half4(col.rgb, col.a);
    #endif


// 副纹理颜色
#if _USE_SECONDARYTEX
	half4 secCol = SAMPLE_TEXTURE2D(_SecondaryTex, sampler_SecondaryTex, i.uvSec);
	col *= secCol;
#endif




// detial
#if _USE_DETAIL
	if (_UV_Polar_Detial > 0)
		i.uv.zw = UVPolar(i.uv.zw, _PolarDetialTiling.zw, _PolarDetialTiling.x, _PolarDetialTiling.y);

	half2 uvDetailSpeed = UVSpeed(_UV_Speed_U_Detail, _UV_Speed_V_Detail);
	i.uv.zw += uvDetailSpeed;

#if _USE_DISTORT
	half4 detail = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv.zw + distort);
#else
	half4 detail = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv.zw);
#endif

	detail *= _DetailColor;

	col.rgb += detail.rgb * _DetailTexColorAdd;
	col.rgb = lerp(col.rgb, detail.rgb, _DetailTexColorLerp);
	col.a += detail.a * _DetailTexAlphaAdd;
	col.a = lerp(col.a, detail.a, _DetailTexAlphaLerp);
#endif
	float tex_r = col.r;                                                     //提取贴图的Alpha通道
	col = col * color * i.color;

	col.a = saturate(lerp(col.a, tex_r, _AorR) * _Alpha * i.color.a);

// rim
#if _USE_RIM
	half rim = 1.0 - saturate(dot(i.viewDir, i.normal));
	rim = saturate(pow(rim, _RimPower));

	if (_RimRevert > 0)
		rim = 1 - rim;

	half4 rimCol = _RimColor * pow(rim, _RimPower);
	col.rgb += rimCol.rgb;

	if (_RimAlpha > 0)
	{
		col.a *= rim;
	}

#endif

// dissolve
#if _USE_DISSOLVE

    float2 dissolveUV = i.uv2.xy + UVSpeed(_Dissolve_Speed_U, _Dissolve_Speed_V) + i.uv3.yz;

#if _USE_DISTORT

    float2 dissolveUV_distort = dissolveUV + distort * _DistortStrength;

    half dissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
    half dissolve_dis = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV_distort).r;
    dissolve = lerp(dissolve, dissolve_dis, _DissolveDistort);
#else

    half dissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
#endif


  
    half dissAmount = saturate(lerp(_DissolveStrength, i.uv3.x, _DissolveAlpha));

    half test = saturate(dissolve - dissAmount);
    half smooth = lerp(0, _DissolveSmooth, dissAmount);
    half t = smoothstep(0, smooth, test);

    half width = step(t + _DissolveWidth, _DissolveSmooth);
    half Dissolve = step(t, _DissolveSmooth);
    half3 WidthColor = (Dissolve - width) * _DissolveColor;


    col.rgb += WidthColor;
    col.a *= t;
#endif




// mask
#if _USE_MASK
	half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv1.xy); 

#if _USE_DISTORT
    // 扭曲UV
    float2 maskUV_distort = i.uv1.xy + distort * _MaskDistortStrength;	  // 使用遮罩扭曲强度控制扭曲效果
	half4 mask_dis = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskUV_distort);
	mask = lerp(mask, mask_dis, _MaskDistort);
#endif

	// 贴图通道关键字
    #if defined(_MASKTEX_CHANNEL_R)
        mask = half4(mask.r, mask.r, mask.r, mask.a);
    #elif defined(_MASKTEX_CHANNEL_G)
        mask = half4(mask.g, mask.g, mask.g, mask.a);
    #elif defined(_MASKTEX_CHANNEL_B)
        mask = half4(mask.b, mask.b, mask.b, mask.a);
    #elif defined(_MASKTEX_CHANNEL_A)
        mask = half4(mask.a, mask.a, mask.a, mask.a);
    #elif defined(_MASKTEX_CHANNEL_ALL)
        // 保持原色
		mask = half4(mask.rgb, mask.a);
    #endif


	half4 alphaMask = mask * _MaskTexColor;
	col *= alphaMask;
	col.a *= lerp(mask.r, mask.a, _MaskTexAorR);                                          //输出Alpha                                   
#endif

// 深度计算
#if _USE_SOFTPARTICLE

	float2 screenPos = i.projPos.xy / i.projPos.w;
	float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
	float EyeD = LinearEyeDepth(sceneZ,_ZBufferParams);  


	float fade = saturate( (EyeD - i.projPos.w) / _SoftFade);
	col.a *= fade;
#endif

// hsv
#if _USE_CHANGECOLOR

	half lum = (col.r + col.g + col.b)/3;

	//half gray = dot(col.rgb,float3(0.299,0.587,0.114));                             //灰度

	col.rgb = _ChangeColor * lum;  
#endif
    col = pow(abs(col), _Power); 


	return col;
}




//=========================================================   输出颜色 ========================================================================================

half4 fragFront(v2f i) : SV_Target
{

	_Color *= _Glowintensity;
	half4 CustomColor = _Color * i.uv3.w; // 使用传入Custom控制强度


    half4 col = frag(i, lerp(_Color, CustomColor, _UseCustomColor)); 

    return col;
}
#endif


//语法修改成SRP Batcher
