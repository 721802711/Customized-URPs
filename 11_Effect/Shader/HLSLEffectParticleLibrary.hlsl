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

	half4 _Color;
	half4 _DetailColor;
	half4 _MaskTexColor;
	half4 _DissolveColor;
	half4 _RimColor;
	half4 _ChangeColor;


	half4 _PolarMainTiling;	
	half4 _PolarDetialTiling;

	half _Alpha;
	half _Power;
	half _AorR;
	half _UVRot;
	half _SoftFade;
	half _UV2;


	//边缘光

	half _RimPower;
	half _RimRevert;
	half _RimAlpha;

	// uv极坐标
	half _UV_Polar_Main;
	half _MainTexAngle;

	// uv速度
	half _UV_Speed_U_Main;
	half _UV_Speed_V_Main;

	half _UV_Polar_Detial;
	half _UV_Speed_U_Detail;
	half _UV_Speed_V_Detail;
	half _DetailTexAngle;
	half _DetailTexColorAdd;
	half _DetailTexColorLerp;
	half _DetailTexAlphaAdd;
	half _DetailTexAlphaLerp;
	half _UVRot_Detail;
	

	// 遮罩
	half _UV_Speed_U_Mask;
	half _UV_Speed_V_Mask;
	half _MaskTexAngle;

	half _UVRot_Mask;
	half _MaskTexAorR;
	half _MaskTexRotSpeed;
	half _MaskUvOffsetMain;
	half _MaskUvOffset;
	half _MaskOne_UV;
	half _MaskUV_one;

	half _speedU;
	half _speedV;


	// 扭曲

	half _DistortStrength;
	half _DistortTex_Speed_U;
	half _DistortTex_Speed_V;
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

CBUFFER_END

sampler2D _CameraDepthTexture;            SAMPLER(sampler_CameraDepthTexture);

sampler2D _MainTex;
sampler2D _DetailTex;
sampler2D _MaskTex;
sampler2D _DistortTex;
sampler2D _DissolveTex;



half _UV_Speed_U_Main_Mirror;
half _UV_Speed_V_Main_Mirror;

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

#if (defined(_USE_SOFTPARTICLE))
		float4 projPos : TEXCOORD2;
#endif

#if _USE_MASK
	
	float4 uv3 : TEXCOORD7; 
	
#if _USE_DISTORT
	float4 uv1 : TEXCOORD3;
#else
	float2 uv1 : TEXCOORD3;
#endif
#else
#if _USE_DISTORT
	float2 uv1 : TEXCOORD3;
#endif
	
#endif

#if _USE_RIM
	float3 viewDir : TEXCOORD4;
	half3 normal : TEXCOORD5;
#endif

#if _USE_DISSOLVE
	float2 uv2 : TEXCOORD6;
#if !_USE_MASK                                 // 如果不开启 Mask 就定义 UV3 
	float4 uv3 : TEXCOORD7; 
#endif
	
#endif
};



//=========================================================   顶点着色器 ========================================================================================
v2f vert(appdata v)
{
	v2f o;

	o.vertex = TransformObjectToHClip(v.positionOS.xyz);
	o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	o.color = v.color;


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
	o.uv1.xy = TRANSFORM_TEX(v.uv, _MaskTex);
	o.uv3 = v.texcoord1;
	half2 uvMaskSpeed = UVSpeed(_UV_Speed_U_Mask, _UV_Speed_V_Mask);
	half2 oneMaskUV = half2(_speedU, _speedV);
	half2 oneMaskcUSTOMUV = half2(o.uv3.y, o.uv3.z);
	half2 MsakUV_oneCustom = lerp(oneMaskUV, oneMaskcUSTOMUV, _MaskOne_UV);       //启用Custom Y
	
	half2 MsakUV = lerp(uvMaskSpeed, MsakUV_oneCustom, _MaskUV_one);       

	if (_UVRot_Mask != 0)
	{
		half2 uvMaskRot = UVRotate(o.uv1.xy, _MaskTexAngle + _MaskTexRotSpeed * _Time.y);
		o.uv1.xy = uvMaskRot + uvMaskSpeed;
	}
	else
	{
		o.uv1.xy += MsakUV;
	}

	if (_MaskUvOffsetMain !=0)
    {
       o.uv1.x += v.uv1.x * _MaskUvOffset;
	  
    }
	else{}

	
	
	
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
	if (_UV_Polar_Main > 0)
		i.uv.xy = UVPolar(i.uv.xy, _PolarMainTiling.zw, _PolarMainTiling.x, _PolarMainTiling.y);

	// uv speed
	half2 uvMainSpeed = UVSpeed(_UV_Speed_U_Main, _UV_Speed_V_Main);
	uvMainSpeed.x = lerp(uvMainSpeed.x, -uvMainSpeed.x, _UV_Speed_U_Main_Mirror);
	uvMainSpeed.y = lerp(uvMainSpeed.y, -uvMainSpeed.y, _UV_Speed_V_Main_Mirror);
	i.uv.xy += uvMainSpeed;

	// distort
#if _USE_DISTORT
#if _USE_MASK
	half4 distortTex = tex2D(_DistortTex, i.uv1.zw);
#else
	half4 distortTex = tex2D(_DistortTex, i.uv1.xy);
#endif
	half distort = distortTex.a * distortTex.r;

	half4 col = tex2D(_MainTex, i.uv + distort * _DistortStrength);

#else
    
    half4 col = tex2D(_MainTex, i.uv);
#endif

	// detial
#if _USE_DETAIL
	if (_UV_Polar_Detial > 0)
		i.uv.zw = UVPolar(i.uv.zw, _PolarDetialTiling.zw, _PolarDetialTiling.x, _PolarDetialTiling.y);

	half2 uvDetailSpeed = UVSpeed(_UV_Speed_U_Detail, _UV_Speed_V_Detail);
	i.uv.zw += uvDetailSpeed;

#if _USE_DISTORT
	half4 detail = tex2D(_DetailTex, i.uv.zw + distort);
#else
	half4 detail = tex2D(_DetailTex, i.uv.zw);
#endif

	detail *= _DetailColor;

	col.rgb += detail.rgb * _DetailTexColorAdd;
	col.rgb = lerp(col.rgb, detail.rgb, _DetailTexColorLerp);
	col.a += detail.a * _DetailTexAlphaAdd;
	col.a = lerp(col.a, detail.a, _DetailTexAlphaLerp);
#endif
	float tex_r = col.r;                                                     //提取贴图的Alpha通道
	col = col * color * i.color;
    col.a = saturate(lerp(col.a, tex_r, _AorR) * _Alpha);

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
#if _USE_DISTORT
	half dissolve = tex2D(_DissolveTex, i.uv2.xy);
	half dissolve_dis = tex2D(_DissolveTex, i.uv2.xy + distort * _DistortStrength);
	dissolve = lerp(dissolve, dissolve_dis, _DissolveDistort);
#else
	half dissolve = tex2D(_DissolveTex, i.uv2.xy);
#endif


	half dissAmount = lerp(_DissolveStrength, i.uv3.x, _DissolveAlpha);       //启用Custom
	
	half test = saturate(dissolve - dissAmount);


	half smooth = lerp(0, _DissolveSmooth, dissAmount);
	half t = smoothstep(0, smooth, test);
	
	half width = step(t + _DissolveWidth , _DissolveSmooth);
	half Dissolve = step(t, _DissolveSmooth);
	half3 WidthColor = (Dissolve - width) * _DissolveColor;
	
	col.rgb = col.rgb + WidthColor ;
	col.a = col.a * t;
#endif

	// mask
#if _USE_MASK
	half4 mask = tex2D(_MaskTex, i.uv1.xy);
	half4 alphaMask = mask * _MaskTexColor;
	col *= alphaMask;
	col.a *= lerp(mask.r, mask.a, _MaskTexAorR);                                          //输出Alpha                                   
#endif

	// 深度计算
#if _USE_SOFTPARTICLE

	float2 screenPos = i.projPos.xy / i.projPos.w;
	float sceneZ = tex2D(_CameraDepthTexture,screenPos).r;
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
    col = pow(col, _Power);
	return col;
}

//=========================================================   输出颜色 ========================================================================================

half4 fragFront(v2f i) : SV_Target
{
    half4 col = frag(i, _Color);
	//half4 col = frag(i);
    return col;
}
#endif


//语法修改成SRP Batcher