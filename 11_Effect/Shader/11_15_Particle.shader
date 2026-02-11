Shader "DFW/Effect/Particle"
{
    Properties
    {
		//基础
		[HDR]_Color ("颜色", Color) = (1, 1, 1, 1)
		[MaterialToggle]_UseCustomColor("使用Custom控制强度变化", float) = 0
		_Glowintensity ("发光强度", Range(1, 10)) = 1         // 发光强度
		_Alpha ("Alpha", Range(0, 5)) = 1
        _MainTex ("纹理", 2D) = "white" {}

		_MainTexWrap("主贴图 WrapMode (U,V)", Vector) = (0,0,0,0)

		// 使用 KeywordEnum 定义通道
		[KeywordEnum(All, R, G, B, A)]
        _MainTex_Channel("MainTex_Channel", Float) = 0

		[MaterialToggle]_AorR("使用R当Alpha通道", float) = 0
		_Power("对比度",Range(1.0, 10)) = 1

		//极坐标
		[Header(UV Polar)]
		[MaterialToggle]_UV_Polar_Main("uv 极坐标(中心方向)", float) = 0
		_PolarMainTiling ("极坐标缩放(Tiling: x, y; Offset: z, w)", vector) = (1, 1, 0, 0)
		//软粒子
		[Header(Soft Particle)]
		[Toggle(_USE_SOFTPARTICLE)]_Toggle_USE_SOFTPARTICLE_ON("软粒子", float) = 0
		_SoftFade ("柔和度", Range(0.01, 30)) = 1.0

		[Toggle(_USE_CUSTOM2_MAINUV)] _UseCustom2MainUV ("UseCustom2MainUV", Float) = 0  // 新增属性，控制是否使用 Custom2 作为主贴图 UV 偏移

		//UV速度
		[Header(UV speed)]
		_UV_Speed_U_Main ("纹理U方向速度", float) = 0
		_UV_Speed_V_Main ("纹理V方向速度", float) = 0
		//贴图旋转
		[Header(UV rotation)]
		[MaterialToggle]_UVRot("uv 旋转", float) = 0
		_MainTexAngle ("纹理旋转", Range(0, 1)) = 0



		// 副纹理
		[Header(SecondaryTex)]
		[Toggle(_USE_SECONDARYTEX)]_USE_SECONDARYTEX("副纹理", float) = 0
		_SecondaryTex ("副纹理", 2D) = "white" {}
		[Header(UV speed)]
		_SecondaryTex_Speed_U ("副纹理U方向速度", float) = 0
		_SecondaryTex_Speed_V ("副纹理V方向速度", float) = 0


		//遮罩
		[Header(Mask)]
		[Toggle(_USE_MASK)]_USE_MASK("遮罩纹理", float) = 0 
		// 使用 KeywordEnum 定义通道
		[KeywordEnum(All, R, G, B, A)]
        _MaskTex_Channel("MaskTex_Channel", Float) = 0

		_MaskTexWrap("遮罩贴图 WrapMode (U,V)", Vector) = (0,0,0,0)



		_MaskTex ("遮罩纹理", 2D) = "white" {}
		[MaterialToggle]_MaskTexAorR("使用R当Alpha通道", float) = 0
		[MaterialToggle]_MaskUV_one("UV循环或者一次性", float) = 0
		[Space(10)]
		_UV_Speed_U_Mask ("纹理U方向速度", float) = 0
		_UV_Speed_V_Mask ("纹理V方向速度", float) = 0
		[Space(10)]
		[MaterialToggle]_MaskOne_UV("随粒子Custom_Y值UV", float) = 0

		_speedU ("纹理U方向", Range(-1,1)) = 0
		_speedV ("纹理V方向", Range(-1,1)) = 0

		[MaterialToggle]_UVRot_Mask("遮罩纹理uv 旋转", float) = 0
		_MaskTexAngle ("遮罩纹理旋转", Range(0, 1)) = 0
		_MaskTexRotSpeed ("遮罩旋转速度", float) = 0

		[HDR]_MaskTexColor ("遮罩系数", Color) = (0, 0, 0, 1)

		[MaterialToggle] _MaskUvOffsetMain("遮罩UV偏移", float) = 0
		_MaskUvOffset("遮罩UV偏移系数",Range(0,5))=0

		[MaterialToggle]_MaskDistort("遮罩开启扭曲", float) = 0
		_MaskDistortStrength ("遮罩扭曲强度", Range(0,1)) = 0.1

		//扭曲
		[Header(Distort)]
		[Toggle(_USE_DISTORT)]_Toggle_USE_DISTORT_ON("扭曲", float) = 0
		_DistortTex ("扭曲纹理", 2D) = "whiter" {}
		_DistortStrength ("扭曲强度", Range(-1.0, 1.0)) = 0
		_DistortTex_Speed_U ("U 方向扭曲速度", float) = 0
		_DistortTex_Speed_V ("V 方向扭曲速度", float) = 0
		[MaterialToggle]_UVRot_DistortTex("扭曲纹理uv 旋转", float) = 0
		_DistortTexRotSpeed ("扭曲旋转速度", float) = 0

		//Fresnel
		[Space(10)]
		[Header(Rim)]
		[Toggle(_USE_RIM)]_Toggle_USE_RIM_ON("边缘光", float) = 0
		[HDR]_RimColor ("边缘光颜色", Color) = (1, 1, 1, 1)
		_RimPower ("边缘光强度", Range(0, 10)) = 1
		[MaterialToggle]_RimRevert("边缘光反向", float) = 0
		[MaterialToggle]_RimAlpha("边缘光Alpha反向", float) = 0

		//溶解
		[Space(10)]
		[Header(Dissolve)]
		[Toggle(_USE_DISSOLVE)]_Toggle_USE_DISSOLVE_ON("溶解", float) = 0

		[MaterialToggle]_DissolveAlpha("随粒子Custom值溶解", float) = 0
		[MaterialToggle]_DissolveDistort("溶解开启扭曲", float) = 0

		_DissolveTex ("溶解贴图", 2D) = "white" {}
		_DissolveStrength ("溶解度", Range(0, 1)) = 0
		[HDR]_DissolveColor ("溶解边缘颜色", Color) = (1, 1, 1, 1)
		_DissolveWidth ("溶解边缘宽度", Range(0, 1)) = 0 
		_DissolveSmooth ("边缘硬度", Range(0, 10)) = 0 

		_Dissolve_Speed_U ("溶解纹理U方向速度", float) = 0
		_Dissolve_Speed_V ("溶解纹理V方向速度", float) = 0

		//整体调色
		[Header(ChangeColor)]
		[Toggle(_USE_CHANGECOLOR)]_Toggle_USE_CHANGECOLOR_ON("换色", float) = 0
		[HDR]_ChangeColor ("换色", Color) = (0.5, 0.5, 0.5, 1)

		// [Header(Bloom)]
        // _BloomThreshold ("Bloom 阈值(作用于alpha mask)", Range(0, 1)) = 1

		[Space(30)]
        [Enum(Off, 0, On, 1)] _zWrite("ZWrite", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest("ZTest", Float) = 4
		[Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1

    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_zWrite]
			ZTest[_zTest]
			Cull[_cull]
			Lighting Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragFront
            #pragma target 2.0

			#pragma multi_compile_particles

			#pragma shader_feature _USE_SOFTPARTICLE
			#pragma shader_feature _USE_DETAIL
			#pragma shader_feature _USE_MASK
			#pragma shader_feature _USE_DISTORT
			#pragma shader_feature _USE_RIM
			#pragma shader_feature _USE_DISSOLVE
			#pragma shader_feature _USE_CHANGECOLOR
			#pragma shader_feature _USE_SECONDARYTEX            // 副纹理
			#pragma multi_compile __ _UNITY_RENDER
			

			#pragma shader_feature_local _USE_CUSTOM2_MAINUV    // 新增Custom2控制主贴图UV


			// 贴图通道关键字	
			#pragma multi_compile _MAINTEX_CHANNEL_ALL _MAINTEX_CHANNEL_R _MAINTEX_CHANNEL_G _MAINTEX_CHANNEL_B _MAINTEX_CHANNEL_A
			#pragma multi_compile _MASKTEX_CHANNEL_ALL _MASKTEX_CHANNEL_R _MASKTEX_CHANNEL_G _MASKTEX_CHANNEL_B _MASKTEX_CHANNEL_A


			#include "HLSLEffectParticleLibrary.hlsl"

            ENDHLSL
        }
    }

	Fallback "Transparent/VertexLit"
	CustomEditor "EffectShaderGUI"
}
