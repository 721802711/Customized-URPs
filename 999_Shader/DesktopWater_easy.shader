// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "WL3/Scene/DesktopWater_easy"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_WaterColor("Water Color", Color) = (0.1176471,0.6348885,1,0)
		_WaterShallowColor("WaterShallowColor", Color) = (0.4191176,0.7596349,1,0)
		//_Wavetint("Wave tint", Range( -1 , 1)) = 0.1
		_FresnelColor("Fresnel Color", Color) = (1,1,1,0.484)
		_RimColor("Rim Color", Color) = (1,1,1,0.5019608)
		_NormalStrength("NormalStrength", Range( 0 , 1)) = 0.25
		_Transparency("Transparency", Range( 0 , 1)) = 0.75
		_Glossiness("Glossiness", Range( 0 , 1)) = 0.85
		//_Fresnelexponent("Fresnel exponent", Float) = 4
		//_ReflectionStrength("Reflection Strength", Range( 0 , 1)) = 0
		//_ReflectionFresnel("Reflection Fresnel", Range( 2 , 10)) = 5
		//_RefractionAmount("Refraction Amount", Range( 0 , 0.2)) = 0.05
		//_ReflectionRefraction("ReflectionRefraction", Range( 0 , 0.2)) = 0.05
		_Worldspacetiling("Worldspace tiling", Float) = 1
		_NormalTiling("NormalTiling", Range( 0 , 1)) = 0.9
		_EdgeFade("EdgeFade", Range( 0.01 , 3)) = 0.2448298
		_RimSize("Rim Size", Range( 0 , 20)) = 6
		_Rimfalloff("Rim falloff", Range( 0.1 , 50)) = 10
		//_Rimtiling("Rim tiling", Float) = 0.5
		//_FoamOpacity("FoamOpacity", Range( -1 , 1)) = 0.05
		//_FoamDistortion("FoamDistortion", Range( 0 , 3)) = 0.45
		//[IntRange]_UseIntersectionFoam("UseIntersectionFoam", Range( 0 , 1)) = 0
		//_FoamSpeed("FoamSpeed", Range( 0 , 1)) = 0.1
		//_FoamSize("FoamSize", Float) = 0
		//_FoamTiling("FoamTiling", Float) = 0.05
		_Depth("Depth", Range( 0 , 100)) = 15
		_Wavesspeed("Waves speed", Range( 0 , 10)) = 0.75
		_WaveHeight("Wave Height", Range( 0 , 1)) = 0.05
		_WaveFoam("Wave Foam", Range( 0 , 10)) = 0
		[NoScaleOffset][Normal]_Normals("Normals", 2D) = "bump" {}
		//_WaveSize("Wave Size", Range( 0 , 10)) = 0.1
		//[NoScaleOffset]_Shadermap("Shadermap", 2D) = "black" {}
		_WaveDirection("WaveDirection", Vector) = (1,0,0,0)
		//_RimDistortion("RimDistortion", Range( 0 , 0.2)) = 0.1
		//[NoScaleOffset]_GradientTex("GradientTex", 2D) = "gray" {}
		_MacroBlendDistance("MacroBlendDistance", Range( 250 , 3000)) = 2000
		//[Toggle]_MACRO_WAVES("MACRO_WAVES", Int) = 0
		//[Toggle]_USE_VC_INTERSECTION("USE_VC_INTERSECTION", Float) = 0
		//[Toggle]_SECONDARY_WAVES("SECONDARY_WAVES", Int) = 0
		//_ENABLE_VC("ENABLE_VC", Float) = 0
		[Toggle][HideInInspector]_RT_REFRACTION("RT_REFRACTION", Float) = 0
		[HideInInspector]_RefractionTex("RefractionTex", 2D) = "white" {}
		//[Toggle]_ENABLE_SHADOWS("ENABLE_SHADOWS", Float) = 0
		[Toggle]_LIGHTING("LIGHTING", Int) = 1
		_LightDir("Light Dir",Vector) = (0,0,0,0)
		_LightColor("Light Color",Color) = (1,1,1,1)
		_LightPower("Light Power",Float) = 1
		//[Toggle]_Unlit("Unlit", Float) = 0
		//_ENABLE_GRADIENT("_ENABLE_GRADIENT", Range( 0 , 1)) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" "IsEmissive" = "true"  }
		LOD 200
		Cull Back
		//Blend SrcColor DstColor,SrcAlpha OneMinusSrcAlpha//Blend SrcAlpha OneMinusSrcAlpha
		GrabPass{ "_GrabTexture" }
		CGPROGRAM
		#include "./FakeLightStandard.cginc"
		#pragma target 3.5
		//#pragma shader_feature _SECONDARY_WAVES_ON
		//#pragma shader_feature _MACRO_WAVES_ON
		//#pragma shader_feature _LIGHTING_ON
		#pragma surface surf StandardCustomLighting alpha:fade keepalpha nodirlightmap vertex:vertexDataFunc finalcolor:final
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float2 texcoord_0;
			float2 data897;
			float2 data898;
			float4 screenPos;
			float4 vertexColor : COLOR;
			float2 data899;
			float3 worldPos;
			float3 worldRefl;
			float2 texcoord_1;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			fixed Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float _RT_REFRACTION;
		uniform sampler2D _GrabTexture;
		//uniform float _RefractionAmount;
		uniform sampler2D _Normals;
		uniform float _NormalTiling;
		uniform float _Worldspacetiling;
		uniform float _Wavesspeed;
		uniform float4 _WaveDirection;
		uniform sampler2D _RefractionTex;
		uniform float4 _WaterShallowColor;
		uniform float4 _WaterColor;
		uniform sampler2D_float _CameraDepthTexture;
		uniform float _Depth;
		//uniform sampler2D _GradientTex;
		//uniform float _ENABLE_GRADIENT;
		uniform float _Transparency;
		uniform float4 _RimColor;
		//uniform float _USE_VC_INTERSECTION;
		//uniform float _ENABLE_VC;
		uniform sampler2D _SWS_RENDERTEX;
		uniform float4 _SWS_RENDERTEX_POS;
		uniform float _Rimfalloff;
		//uniform sampler2D _Shadermap;
		//uniform float _Rimtiling;
		//uniform float _WaveSize;
		//uniform float _RimDistortion;
		uniform float _RimSize;
		//uniform sampler2D _ReflectionTex;
		//uniform float _ReflectionRefraction;
		//uniform float _ReflectionStrength;
		//uniform float _ReflectionFresnel;
		//uniform float _Wavetint;
		//uniform float _FoamOpacity;
		//uniform float _FoamSize;
		//uniform float _FoamDistortion;
		//uniform float _FoamTiling;
		//uniform float _FoamSpeed;
		//uniform float _UseIntersectionFoam;
		uniform float4 _FresnelColor;
		//uniform float _Fresnelexponent;
		uniform float _WaveFoam;
		//uniform float _ENABLE_SHADOWS;
		uniform sampler2D _ShadowMask;
		uniform float _MacroBlendDistance;
		uniform float _NormalStrength;
		uniform float _Glossiness;
		//uniform float _Unlit;
		uniform float _EdgeFade;
		uniform float _WaveHeight;


		uniform float _FogHeight;
			uniform float _FogDensityValue;
			uniform float4 _FogColor;
			uniform float _FogDistance;
			uniform float _FogMaxFactor;

		float2 SPSRUVAdjust922( float4 input )
		{
			#if UNITY_SINGLE_PASS_STEREO
						float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
			    float2 uv = ((input.xy / input.w) - scaleOffset.zw) / scaleOffset.xy;
						#else
						float2 uv = input.xy;
						#endif
						return uv;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.texcoord_0.xy = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			o.data897 = ( (ase_worldPos).xz * float2( 0.1,0.1 ) );
			float2 appendResult500 = (float2(_WaveDirection.x , _WaveDirection.z));
			o.data898 = ( ( ( _Wavesspeed * 0.1 ) * _Time.y ) * appendResult500 );
			float2 appendResult756 = (float2(_SWS_RENDERTEX_POS.z , _SWS_RENDERTEX_POS.w));
			o.data899 = ( ( ( 1.0 - appendResult756 ) / _SWS_RENDERTEX_POS.x ) + ( ( _SWS_RENDERTEX_POS.x / ( _SWS_RENDERTEX_POS.x * _SWS_RENDERTEX_POS.x ) ) * (ase_worldPos).xz ) );
			float3 ase_vertexNormal = v.normal.xyz;
			o.texcoord_1.xy = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
			//float2 temp_output_13_0 = ( -20.0 * o.texcoord_1 );
			//float2 Tiling21 = lerp(temp_output_13_0,( (ase_worldPos).xz * float2( 0.1,0.1 ) ),_Worldspacetiling);
			//float2 temp_output_88_0 = ( ( Tiling21 * _WaveSize ) * 0.1 );
			//float2 WaveSpeed40 = ( ( ( _Wavesspeed * 0.1 ) * _Time.y ) * appendResult500 );
			//float2 temp_output_92_0 = ( WaveSpeed40 * 0.5 );
			//float2 HeightmapUV581 = ( temp_output_88_0 + temp_output_92_0 );
			//float4 tex2DNode94 = tex2Dlod( _Shadermap, float4( HeightmapUV581, 0.0 , 0.0 ) );
			//#ifdef _SECONDARY_WAVES_ON
			//	float staticSwitch721 = ( tex2DNode94.g + tex2Dlod( _Shadermap, float4( ( ( temp_output_88_0 * float2( 2,2 ) ) + ( temp_output_92_0 * float2( -0.5,-0.5 ) ) ), 0.0 , 0.0 ) ).g );
			//#else
			//	float staticSwitch721 = tex2DNode94.g;
			//#endif
			//float temp_output_95_0 = ( _WaveHeight * staticSwitch721 );
			//float3 Displacement100 = ( ase_vertexNormal * temp_output_95_0 );
			//v.vertex.xyz += Displacement100;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			SurfaceOutputStandard s856 = (SurfaceOutputStandard ) 0;
			float2 temp_output_13_0 = ( -20.0 * i.texcoord_0 );
			float2 Tiling21 = lerp(temp_output_13_0,i.data897,_Worldspacetiling);
			float2 temp_output_732_0 = ( _NormalTiling * Tiling21 );
			float2 WaveSpeed40 = i.data898;
			float3 temp_output_51_0 = BlendNormals( UnpackNormal( tex2D( _Normals, ( temp_output_732_0 + -WaveSpeed40 ) ) ) , UnpackNormal( tex2D( _Normals, ( ( temp_output_732_0 * 0.5 ) + WaveSpeed40 ) ) ) );
			float3 NormalsBlended362 = temp_output_51_0;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPos266 = ase_screenPos;
			#if UNITY_UV_STARTS_AT_TOP
			float scale266 = -1.0;
			#else
			float scale266 = 1.0;
			#endif
			float halfPosW266 = ase_screenPos266.w * 0.5;
			ase_screenPos266.y = ( ase_screenPos266.y - halfPosW266 ) * _ProjectionParams.x* scale266 + halfPosW266;
			#ifdef UNITY_SINGLE_PASS_STEREO
			ase_screenPos266.xy = TransformStereoScreenSpaceTex(ase_screenPos266.xy, ase_screenPos266.w);
			#endif
			ase_screenPos266.xyzw /= ase_screenPos266.w;
			float4 input922 = ase_screenPos266;
			float2 localSPSRUVAdjust922922 = SPSRUVAdjust922( input922 );
			float3 temp_output_359_0 = ( ( 0.2 * NormalsBlended362 ) + float3( localSPSRUVAdjust922922 ,  0.0 ) );
			float4 screenColor372 = tex2D( _GrabTexture, temp_output_359_0.xy );
			float4 RefractionResult126 = lerp(screenColor372,tex2D( _RefractionTex, temp_output_359_0.xy ),_RT_REFRACTION);
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			//Stylized Water custom depth
			float screenDepth641 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(ase_screenPos))));
			float distanceDepth641 = abs( ( screenDepth641 - LinearEyeDepth( ase_screenPosNorm.z ) ) / (  lerp( 1.0 , ( 1.0 / _ProjectionParams.z ) , unity_OrthoParams.w) ) );
			float DepthTexture494 = distanceDepth641;
			float Depth479 = saturate( ( DepthTexture494 / _Depth ) );
			float4 lerpResult478 = lerp( _WaterShallowColor , _WaterColor , Depth479);
			float2 appendResult661 = (float2(Depth479 , 1.0));
			//float4 tex2DNode659 = tex2D( _GradientTex, appendResult661 );
			//float4 lerpResult942 = lerp( lerpResult478 , tex2DNode659 , _ENABLE_GRADIENT);
			float4 lerpResult942 = lerpResult478;
			float4 VertexColors810 = float4( 0.0,0,0,0 );
			float2 RT_UV763 = i.data899;
			float4 tex2DNode747 = tex2D( _SWS_RENDERTEX, RT_UV763 );
			float RT_Intersection748 = ( 1.0 - tex2DNode747.r );
			float IntersectionSource776 = ( DepthTexture494 + RT_Intersection748 );
			//float2 temp_output_24_0 = ( Tiling21 * _Rimtiling );
			//float2 temp_output_88_0 = ( ( Tiling21 * _WaveSize ) * 0.1 );
			//float2 temp_output_92_0 = ( WaveSpeed40 * 0.5 );
			//float2 HeightmapUV581 = ( temp_output_88_0 + temp_output_92_0 );
			//float4 tex2DNode94 = tex2D( _Shadermap, HeightmapUV581 );
			//#ifdef _SECONDARY_WAVES_ON
			//	float staticSwitch721 = ( tex2DNode94.g + tex2D( _Shadermap, ( ( temp_output_88_0 * float2( 2,2 ) ) + ( temp_output_92_0 * float2( -0.5,-0.5 ) ) ) ).g );
			//#else
				float staticSwitch721 = 0;//tex2DNode94.g;
			//#endif
			float Heightmap99 = staticSwitch721;
			//float temp_output_30_0 = ( tex2D( _Shadermap, ( ( 0.5 * temp_output_24_0 ) + ( Heightmap99 * _RimDistortion ) ) ).b * tex2D( _Shadermap, ( temp_output_24_0 + WaveSpeed40 ) ).b );
			//float Intersection42 = saturate( ( _RimColor.a * ( 1.0 - ( ( ( IntersectionSource776 / _Rimfalloff ) * temp_output_30_0 ) + ( IntersectionSource776 / _RimSize ) ) ) ) );
			float Intersection42 = saturate( ( _RimColor.a * ( 1.0 - ( ( IntersectionSource776 / _RimSize ) ) ) ) );
			//float lerpResult943 = lerp( _WaterShallowColor.a , tex2DNode659.a , _ENABLE_GRADIENT);
			float lerpResult943 = _WaterShallowColor.a;
			float temp_output_149_0 = ( ( _Transparency + Intersection42 ) - ( ( 1.0 - Depth479 ) * ( 1.0 - lerpResult943 ) ) );
			float Opacity121 = saturate( temp_output_149_0 );
			float4 lerpResult374 = lerp( RefractionResult126 , lerpResult942 , Opacity121);
			//float4 Reflection265 = tex2D( _ReflectionTex, ( float3( localSPSRUVAdjust922922 ,  0.0 ) + ( ( NormalsBlended362 + Heightmap99 ) * _ReflectionRefraction ) ).xy );
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			//float fresnelFinalVal508 = (0.0 + _ReflectionFresnel*pow( 1.0 - dot( ase_worldNormal, worldViewDir ) , 5.0));
			float4 lerpResult297 = lerpResult374;//lerp( lerpResult374 , Reflection265 , saturate( ( ( Opacity121 * _ReflectionStrength ) * fresnelFinalVal508 ) ));
			float4 WaterColor350 = lerpResult297;
			//float4 temp_cast_6 = (( Heightmap99 * _Wavetint )).xxxx;
			float4 RimColor102 = _RimColor;
			float4 lerpResult61 = lerp( saturate( ( WaterColor350 - float4(0,0,0,0) ) ) , ( RimColor102 * 3.0 ) , Intersection42);
			float SteepnessMask820 = saturate( ( 1.0 - pow( ase_worldNormal.y , 2.0 ) ) );
			//float temp_output_609_0 = ( Heightmap99 * _FoamDistortion );
			//float2 temp_output_634_0 = ( WaveSpeed40 * _FoamSpeed );
			//float4 tex2DNode67 = tex2D( _Shadermap, ( ( _FoamTiling * ( -temp_output_609_0 + Tiling21 ) ) + temp_output_634_0 ) );
			//float lerpResult601 = lerp( step( _FoamSize , ( tex2D( _Shadermap, ( ( ( temp_output_609_0 + ( Tiling21 * 0.5 ) ) * _FoamTiling ) + temp_output_634_0 ) ).r - tex2DNode67.r ) ) , ( 1.0 - tex2DNode67.b ) , _UseIntersectionFoam);
			float lerpResult601 = 1;//lerp( step( _FoamSize , 0) ) , ( 1.0) , _UseIntersectionFoam);
			float Foam73 = ( ( SteepnessMask820) * lerpResult601 );
			float4 FresnelColor206 = _FresnelColor;
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float fresnelFinalVal199 = (0.0 + 1.0*pow( 1.0 - dot( ase_vertexNormal, worldViewDir ) , 100.0 ));
			float clampResult505 = clamp( ( _FresnelColor.a * fresnelFinalVal199 ) , 0.0 , 1.0 );
			float Fresnel205 = clampResult505;
			float4 lerpResult207 = lerp( ( lerpResult61 + Foam73 ) , FresnelColor206 , Fresnel205);
			float4 temp_cast_7 = (2.0).xxxx;
			float FoamTex244 = lerpResult601;
			float WaveFoam221 = saturate( ( ( pow( staticSwitch721 , 2.0 ) * _WaveFoam ) * FoamTex244 ) );
			float4 lerpResult223 = lerp( lerpResult207 , temp_cast_7 , WaveFoam221);
			float4 temp_cast_8 = (1.0).xxxx;
			float4 tex2DNode833 = tex2D( _ShadowMask, localSPSRUVAdjust922922 );
			//float4 Shadows834 = lerp(temp_cast_8,saturate( ( unity_AmbientSky / ( 1.0 - tex2DNode833.r ) ) ),_ENABLE_SHADOWS);
			float4 Shadows834 = temp_cast_8;
			float4 FinalColor114 = ( lerpResult223 * Shadows834 );
			s856.Albedo = FinalColor114.rgb;
			//#ifdef _MACRO_WAVES_ON
			//	float2 staticSwitch946 = ( WaveSpeed40 + ( temp_output_732_0 * 0.1 ) );
			//#else
				float2 staticSwitch946 = float2( 0.0,0 );
			//#endif
			//#ifdef _MACRO_WAVES_ON
			//	float3 staticSwitch947 = UnpackNormal( tex2D( _Normals, staticSwitch946 ) );
			//#else
				float3 staticSwitch947 = float3( 0.0,0,0 );
			//#endif
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			//#ifdef _MACRO_WAVES_ON
			//	float staticSwitch948 = saturate( ( distance( ase_vertex3Pos , _WorldSpaceCameraPos ) / _MacroBlendDistance ) );
			//#else
				float staticSwitch948 = 0.0;
			//#endif
			float3 lerpResult674 = lerp( temp_output_51_0 , staticSwitch947 , staticSwitch948);
			//#ifdef _MACRO_WAVES_ON
			//	float3 staticSwitch680 = lerpResult674;
			//#else
				float3 staticSwitch680 = temp_output_51_0;
			//#endif
			float3 lerpResult621 = lerp( float3(0,0,1) , staticSwitch680 , saturate( ( Intersection42 + _NormalStrength ) ));
			float3 NormalMap52 = lerpResult621;
			s856.Normal = WorldNormalVector( i, NormalMap52);
			s856.Emission = float3( 0,0,0 );
			s856.Metallic = 0.0;
			float GlossinessParam877 = _Glossiness;
			s856.Smoothness = GlossinessParam877;
			s856.Occlusion = 1.0;

			gi.light.ndotl = LambertTerm( s856.Normal, gi.light.dir );
			data.light = gi.light;

			UnityGI gi856 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g856;
			g856.roughness = 1 - s856.Smoothness;
			g856.reflUVW = reflect( -data.worldViewDir, s856.Normal );
			gi856 = UnityGlobalIllumination( data, s856.Occlusion, s856.Normal, g856 );
			#endif

			float3 surfResult856 = FakeLightingStandard ( s856, viewDir, gi856 ).rgb;
			surfResult856 += s856.Emission;

			float ShadowMask944 = tex2DNode833.r;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			float dotResult866 = dot( ase_worldlightDir , WorldReflectionVector( i , NormalMap52 ) );
			//#ifdef _LIGHTING_ON
			//	float4 staticSwitch857 = float4( surfResult856 , 0.0 );
			//#else
			//	float4 staticSwitch857 = saturate( ( ( ShadowMask944 * pow( max( 0.0 , dotResult866 ) , ( GlossinessParam877 * 128.0 ) ) ) + float4( _LightColor0.rgb , 0.0 ) * FinalColor114 ) );
			//#endif
			float RT_Opacity750 = tex2DNode747.g;
			float OpacityFinal814 = max(0, saturate( ( DepthTexture494 / _EdgeFade ) )- saturate( ( RT_Opacity750 + (VertexColors810).g ) ) );
			//c.rgb = fixed3(OpacityFinal814,OpacityFinal814,OpacityFinal814);
			c.rgb = surfResult856.rgb;
			c.a = OpacityFinal814;
			return c;
		}
		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		void final(Input IN, SurfaceOutputCustomLightingCustom o, inout fixed4 color) { 
		float falloff = max((IN.worldPos.y - _FogHeight),0)* _FogDensityValue * 0.01;
				float FogDensity = exp(-(falloff * falloff));
				FogDensity = saturate(FogDensity);
				float FogFactor = FogDensity * clamp(distance(IN.worldPos.xyz,_WorldSpaceCameraPos.xyz)/_FogDistance,0,1);
				FogFactor = min(FogFactor,_FogMaxFactor);
				lerp(color.rgb,_FogColor.rgb * 0.5,FogFactor);
               
        } 

		ENDCG
	}
	Fallback "Diffuse"
}
