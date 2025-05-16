
Shader "WL3/Actor/Darren/ActorPBRAnisotropic"
{
	Properties
	{
		//_Color("Color",color) = (1,1,1,1)	//颜色
		_AlbedoMap("AlbedoMap",2D) = "white"{}	//反照率
		_NormalMap("NormalMap",2D) = "bump"{}//法线贴图
		_MaskMap("MaskMap（r环境光,g金属度，b粗糙度,alpha 高光因素）",2D) = "white"{} //金属图，g通道存储金属度，b通道存储光滑度
		_Channel("r空,g空,b控制hdr",2D) = "black"{} //通道图，b通道控制hdr
		[HDR]_GlowColor("GlowColor", Color) = (2.713,0.7297035,0,1)
		//_OcclusionMap("Occlusion",2D) = "white"{}//环境光遮挡纹理
		_Roughness("Roughness 粗糙强度",Range(0,1)) = 0.5 //光滑强度
		_Metallic("Metallic 金属强度",Range(0,1)) = 1 //金属强度
		_CubeMap("CubeMap",Cube) = "_Skybox"{}
		_CubeMapLODBaseLvl("CubeMapLODBaseLvl",Range(0,10)) = 5 //cubemap LOD效果的基础等级
		_AO("AO", Range( 0 , 2)) = 1
		_SideLightColor("SideLightColor 轮廓光颜色", Color) = (0,0,0,1)
		_SideLightScale("SideLightScale 轮廓光强度", Range( 0 , 1)) = 0
		_BackLightColor("BackLightColor 背光颜色",Color) = (1,1,1,1)
		_Power("BackLightPower 背光强度",Range(0,10)) = 1
		_SpecularPower("specular power",Range(1,5)) = 1

		_SpecularColor1 ("高光 1 的颜色",Color) = (1,1,1,1)
		_primaryShift("高光 1 的偏移",Range(-2.0,2.0)) = 0
		_specularPower1("高光 1 的范围",Range(0.0,1000.0)) = 10
		_specularIntensity1("高光 1 的强度",Range(0.0,5.0)) = 1.0
		[HDR]_MaxColor("MaxColor", Color) = (1,1,1,1)
		//_BumpScale("Normal Scale",float) = 1 //法线影响大小
		//_EmissionColor("Color",color) = (0,0,0) //自发光颜色
		//_EmissionMap("Emission Map",2D) = "white"{}//自发光贴图
		
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		#define LX_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
		samplerCUBE _CubeMap;
		float _CubeMapLODBaseLvl;
		inline half4 VertexGI(float2 uv1,float2 uv2,float3 worldPos,float3 worldNormal)
		{
			half4 ambientOrLightmapUV = 0;

			#ifdef LIGHTMAP_ON
				ambientOrLightmapUV.xy = uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#elif UNITY_SHOULD_SAMPLE_SH
				#ifdef VERTEXLIGHT_ON
					ambientOrLightmapUV.rgb = Shade4PointLights(
						unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
						unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
						unity_4LightAtten0,worldPos,worldNormal);
				#endif
				ambientOrLightmapUV.rgb += ShadeSH9(half4(worldNormal,1));
			#endif
			#ifdef DYNAMICLIGHTMAP_ON
				ambientOrLightmapUV.zw = uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
			#endif

			return ambientOrLightmapUV;
		}
		inline half3 ComputeIndirectDiffuse(half4 ambientOrLightmapUV,half occlusion)
		{
			half3 indirectDiffuse = 0;

			#if UNITY_SHOULD_SAMPLE_SH
				indirectDiffuse = ambientOrLightmapUV.rgb;	
			#endif
			#ifdef LIGHTMAP_ON
				indirectDiffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,ambientOrLightmapUV.xy));
			#endif
			#ifdef DYNAMICLIGHTMAP_ON
				indirectDiffuse += DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap,ambientOrLightmapUV.zw));
			#endif

			return indirectDiffuse * occlusion;
		}
		inline half3 BoxProjectedDirection(half3 worldRefDir,float3 worldPos,float4 cubemapCenter,float4 boxMin,float4 boxMax)
		{
			UNITY_BRANCH
			if(cubemapCenter.w > 0.0)
			{
				half3 rbmax = (boxMax.xyz - worldPos) / worldRefDir;
				half3 rbmin = (boxMin.xyz - worldPos) / worldRefDir;

				half3 rbminmax = (worldRefDir > 0.0f) ? rbmax : rbmin;

				half fa = min(min(rbminmax.x,rbminmax.y),rbminmax.z);

				worldPos -= cubemapCenter.xyz;
				worldRefDir = worldPos + worldRefDir * fa;
			}
			return worldRefDir;
		}
		inline half3 SamplerReflectProbe(UNITY_ARGS_TEXCUBE(tex),half3 refDir,half roughness,half4 hdr)
		{
			roughness = roughness * (1.7 - 0.7 * roughness);
			half mip = roughness * 6;
			half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex,refDir,mip);
			return DecodeHDR(rgbm,hdr);
		}
		//计算间接光镜面反射
		inline half3 ComputeIndirectSpecular(half3 refDir,float3 worldPos,half roughness,half occlusion)
		{
			half3 specular = 0;
			half3 refDir1 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
			half3 ref1 = SamplerReflectProbe(UNITY_PASS_TEXCUBE(unity_SpecCube0),refDir1,roughness,unity_SpecCube0_HDR);
			UNITY_BRANCH
			if(unity_SpecCube0_BoxMin.w < 0.99999)
			{
				half3 refDir2 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube1_ProbePosition,unity_SpecCube1_BoxMin,unity_SpecCube1_BoxMax);
				half3 ref2 = SamplerReflectProbe(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0),refDir2,roughness,unity_SpecCube1_HDR);

				specular = lerp(ref2,ref1,unity_SpecCube0_BoxMin.w);
			}
			else
			{
				specular = ref1;
			}
			return specular * occlusion;
		}

		inline half3 FakeComputeIndirectSpecular(half3 refDir,float3 worldPos,half roughness,half occlusion)
		{
			half3 specular = 0;
			half3 refDir1 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
			roughness = roughness * (1.7 - 0.7 * roughness);
			half mip = roughness * 6;
			half4 rgbm =  texCUBElod(_CubeMap,half4(refDir1,mip + _CubeMapLODBaseLvl));
			rgbm.rgb = IsGammaSpace() ? GammaToLinearSpace(rgbm.rgb) : rgbm.rgb;
			half3 ref1 = DecodeHDR(rgbm,unity_SpecCube0_HDR);
			specular = rgbm;
			
			return specular * occlusion;
		}

		inline half ComputeSmithJointGGXVisibilityTerm(half nl,half nv,half roughness)
		{
			half ag = roughness * roughness;
			half lambdaV = nl * (nv * (1 - ag) + ag);
			half lambdaL = nv * (nl * (1 - ag) + ag);
			
			return 0.5f/(lambdaV + lambdaL + 1e-5f);
		}
		inline half ComputeGGXTerm(half nh,half roughness)
		{
			half a = roughness * roughness;
			half a2 = a * a;
			half d = (a2 - 1.0f) * nh * nh + 1.0f;
			return a2 * UNITY_INV_PI / (d * d + 1e-5f);
		}
		inline half3 ComputeFresnelTerm(half3 F0,half cosA)
		{
			return F0 + (1 - F0) * pow(1 - cosA, 5);
		}
		inline half3 ComputeDisneyDiffuseTerm(half nv,half nl,half lh,half roughness,half3 baseColor)
		{
			half Fd90 = 0.5f + 2 * roughness * lh * lh;
			return baseColor * UNITY_INV_PI * (1 + (Fd90 - 1) * pow(1-nl,5)) * (1 + (Fd90 - 1) * pow(1-nv,5));
		}
		inline half3 ComputeFresnelLerp(half3 c0,half3 c1,half cosA)
		{
			half t = pow(1 - cosA,5);
			return lerp(c0,c1,t);
		}

		float3 ShiftTangent(float3 T,float3 N,float shift)
	    	{
	    		float3 shiftedT = T + (shift * N);
	    		return normalize(shiftedT);
	    	}

	    	float StrandSpecular(float3 T,float3 V,float L,float intensity)
	    	{
	    		float3 H = normalize(V + L);
				float dotTH = dot(T,H);
	    		float sinTH = sqrt(1.0 - dotTH * dotTH);
	    		float dirAtten = smoothstep(-1.0,0.0,dot(T,H));
	    		return dirAtten * pow(sinTH,intensity);
	    	}
	ENDCG
	SubShader
	{
		Tags{"Queue"="Geometry+20" "RenderType" = "Opaque"}
		pass
		{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma vertex vert
			#pragma fragment frag



			//half4 _Color;
			sampler2D _AlbedoMap;
			float4 _AlbedoMap_ST;
			sampler2D _MaskMap;
			sampler2D _NormalMap;
			sampler2D _Channel;
			float4 _GlowColor;
			//sampler2D _OcclusionMap;
			half _Metallic;
			half _Roughness;
			float _AO;
			float4 _BackLightColor;
			float _Power;
			float _SpecularPower;
			float _SideLightScale;
			float4 _SideLightColor;
			
			float4 _SpecularColor1;
			half _primaryShift;
			float _specularPower1;
			float _specularIntensity1;

			uniform float4 _MaxColor;
			//float _BumpScale;
			//half4 _EmissionColor;
			//sampler2D _EmissionMap;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				half4 ambientOrLightmapUV : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
				float3 tangentDir : TEXCOORD5;
				SHADOW_COORDS(6) 
				UNITY_FOG_COORDS(7) 

			};

			v2f vert(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_AlbedoMap);

				float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
				half3 worldTangent = UnityObjectToWorldDir(v.tangent);
				half3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

				o.ambientOrLightmapUV = VertexGI(v.texcoord1,v.texcoord2,worldPos,worldNormal);

				o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//世界坐标
				half3 albedo = tex2D(_AlbedoMap,i.uv).rgb;//反照率 * _Color.rgb
				albedo = IsGammaSpace() ? GammaToLinearSpace(albedo) : albedo;
				half4 mask = tex2D(_MaskMap,i.uv);
				mask.rgb = IsGammaSpace() ? GammaToLinearSpace(mask.rgb) : mask.rgb;
				half2 metallicGloss = mask.gb;
				half metallic = metallicGloss.x * _Metallic * mask.a;//金属度
				half roughness = (1 -(1 - metallicGloss.y) * _Roughness * mask.a) ;//粗糙度
				half occlusion = mask.r * _AO;//环境光遮挡
				half3 normalTangent = UnpackNormal(tex2D(_NormalMap,i.uv));
				half3 channel = tex2D(_Channel,i.uv);
				channel = IsGammaSpace() ? GammaToLinearSpace(channel) : channel;
				half bChannel = channel.z;
				//normalTangent.xy *= _BumpScale;
				normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy,normalTangent.xy)));
				half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz,normalTangent),
									dot(i.TtoW1.xyz,normalTangent),dot(i.TtoW2.xyz,normalTangent)));

				half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				half3 backLightDir = half3(-lightDir.x,lightDir.y,-lightDir.z);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half3 refDir = reflect(-viewDir,worldNormal);


				UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

				half3 halfDir = normalize(lightDir + viewDir);
				half3 backHalfDir = normalize(backLightDir + viewDir);
				half nv = saturate(dot(worldNormal,viewDir));
				half nl = saturate(dot(worldNormal,lightDir));
				half backnl = saturate(dot(worldNormal,backLightDir));
				half nh = saturate(dot(worldNormal,halfDir));
				half backnh = saturate(dot(worldNormal,backHalfDir));
				half lv = saturate(dot(lightDir,viewDir));
				half backlv = saturate(dot(backLightDir,viewDir));
				half lh = saturate(dot(lightDir,halfDir));
				half backlh = saturate(dot(backLightDir,backHalfDir));

				half3 specColor = lerp(LX_ColorSpaceDielectricSpec.rgb,albedo,metallic);
				half oneMinusReflectivity = (1- metallic) * LX_ColorSpaceDielectricSpec.a;
				half3 diffColor = albedo * oneMinusReflectivity;
				half3 indirectDiffuse = ComputeIndirectDiffuse(i.ambientOrLightmapUV,occlusion);
				//half3 indirectSpecular = ComputeIndirectSpecular(refDir,worldPos,roughness,occlusion);
				half3 indirectSpecular = FakeComputeIndirectSpecular(refDir,worldPos,roughness,occlusion);//texCUBE(_CubeMap,refDir).rgb * occlusion;
				
				half grazingTerm = saturate((1 - roughness) + (1-oneMinusReflectivity));
				indirectSpecular *= ComputeFresnelLerp(specColor,grazingTerm,nv);
				indirectDiffuse *= diffColor;

				half V = ComputeSmithJointGGXVisibilityTerm(nl,nv,roughness);
				half D = ComputeGGXTerm(nh,roughness);
				half3 F = ComputeFresnelTerm(specColor,lh);

				half backV = ComputeSmithJointGGXVisibilityTerm(backnl,nv,roughness);
				half BackD = ComputeGGXTerm(backnh,roughness);
				half3 backF = ComputeFresnelTerm(specColor,backlh);

				half3 specularTerm = V * D * F;
				half3 backSpecularTerm = backV * BackD *backF;

				half3 diffuseTerm = ComputeDisneyDiffuseTerm(nv,nl,lh,roughness,diffColor);
				half3 backDiffuseTerm = ComputeDisneyDiffuseTerm(nv,backnl,backlh,roughness,diffColor);

				float fresnelNode = (0.0 + _SideLightScale * pow(1.0 - nv,5.0));
				half3 sideColor = (saturate( ( (0.0 + (( atten * 1.3 ) - 0.4) * (1.0 - 0.0) / (1.0 - 0.4)) * fresnelNode * _SideLightColor ) )).rgb;

				//float backFresnelNode = (0.0 + _SideLightScale * pow(1.0 - nv,5.0));
				//half3 backFideColor = (saturate( ( (0.0 + (( atten * 1.3 ) - 0.4) * (1.0 - 0.0) / (1.0 - 0.4)) * backFresnelNode * _SideLightColor ) )).rgb;
				half3 backColor = ((backDiffuseTerm + backSpecularTerm) * _BackLightColor.rgb *backnl ) * _Power ;


				float3 t1 = ShiftTangent(i.tangentDir,worldNormal,_primaryShift);
				float ftr = dot(worldNormal,nh);
				float3 specialColor = _SpecularColor1 * StrandSpecular(t1,viewDir,lightDir,_specularPower1) * (1 - ftr * ftr) * _specularIntensity1;

				half3 color = (UNITY_PI * (diffuseTerm + specularTerm * _SpecularPower) * _LightColor0.rgb * nl 
								+ indirectDiffuse + indirectSpecular) * atten + sideColor + backColor + _GlowColor * bChannel + specialColor;// + emission;
				color = IsGammaSpace() ? LinearToGammaSpace(color) : color;
				color = clamp(color,float3(0,0,0),_MaxColor.rgb);
				UNITY_APPLY_FOG(i.fogCoord, color.rgb);
				//color = indirectSpecular;
				return half4(color,1);
			}

			ENDCG
		}
	}
	FallBack "VertexLit"
}
