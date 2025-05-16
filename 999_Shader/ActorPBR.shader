// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "WL3/Actor/Darren/ActorPBR"
{
	Properties
	{
		//_Color("Color",color) = (1,1,1,1)	//颜色
		_AlbedoMap("AlbedoMap",2D) = "white"{}	//反照率
		_NormalMap("NormalMap",2D) = "bump"{}//法线贴图
		_MaskMap("MaskMap（r环境光,g金属度，b粗糙度,alpha 高光因素）",2D) = "white"{} //金属图，g通道存储金属度，b通道存储光滑度
		_Channel("r(变色通道),g空,b控制hdr",2D) = "black"{} //通道图，r变色区域，b通道控制hdr
		_Dey1("变色颜色",Color) = (1,1,1,1)
		[HDR]_GlowColor("GlowColor", Color) = (2.713,0.7297035,0,1)
		//_OcclusionMap("Occlusion",2D) = "white"{}//环境光遮挡纹理
		_Roughness("Roughness 粗糙强度",Range(0,1)) = 0.5 //光滑强度
		_Metallic("Metallic 金属强度",Range(0,1)) = 1 //金属强度
		_CubeMap("CubeMap",Cube) = "_Skybox"{}
		_CubeMapLODBaseLvl("CubeMapLODBaseLvl",Range(0,10)) = 5 //cubemap LOD效果的基础等级
		_AO("AO", Range( 0 , 2)) = 1
		_FresnelSize ("FresnelSize 反射区域大小", Range(0, 10)) = 3.5
        _FresnelScale ("_Amount 反射强度(值用0)", Range(0, 10)) = 0
        _FresnelColor ("FresnelColor 反射光的颜色", Color) = (1,1,1,1)
		_BackLightColor("BackLightColor 背光颜色",Color) = (1,1,1,1)
		_Power("BackLightPower 背光强度",Range(0,10)) = 1
		_SpecularPower("specular power",Range(1,5)) = 1

		[Toggle] _UseXRay ("Use Xray?", Float ) = 0
		_XRayColor("XRay Color", Color) = (1,1,1,1)
		[HDR]_MaxColor("MaxColor", Color) = (1,1,1,1)
		//_BumpScale("Normal Scale",float) = 1 //法线影响大小
		//_EmissionColor("Color",color) = (0,0,0) //自发光颜色
		//_EmissionMap("Emission Map",2D) = "white"{}//自发光贴图
		
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		#define LX_ColorSpaceDielectricSpec float4(0.04, 0.04, 0.04, 1.0 - 0.04)
		samplerCUBE _CubeMap;
		float _CubeMapLODBaseLvl;
		inline float4 VertexGI(float2 uv1,float2 uv2,float3 worldPos,float3 worldNormal)
		{
			float4 ambientOrLightmapUV = 0;

			#ifdef LIGHTMAP_ON
				ambientOrLightmapUV.xy = uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#elif UNITY_SHOULD_SAMPLE_SH
				#ifdef VERTEXLIGHT_ON
					ambientOrLightmapUV.rgb = Shade4PointLights(
						unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
						unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
						unity_4LightAtten0,worldPos,worldNormal);
				#endif
				ambientOrLightmapUV.rgb += ShadeSH9(float4(worldNormal,1));
			#endif
			#ifdef DYNAMICLIGHTMAP_ON
				ambientOrLightmapUV.zw = uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
			#endif

			return ambientOrLightmapUV;
		}
		inline float3 ComputeIndirectDiffuse(float4 ambientOrLightmapUV,float occlusion)
		{
			float3 indirectDiffuse = 0;

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
		inline float3 BoxProjectedDirection(float3 worldRefDir,float3 worldPos,float4 cubemapCenter,float4 boxMin,float4 boxMax)
		{
			UNITY_BRANCH
			if(cubemapCenter.w > 0.0)
			{
				float3 rbmax = (boxMax.xyz - worldPos) / worldRefDir;
				float3 rbmin = (boxMin.xyz - worldPos) / worldRefDir;

				float3 rbminmax = (worldRefDir > 0.0f) ? rbmax : rbmin;

				float fa = min(min(rbminmax.x,rbminmax.y),rbminmax.z);

				worldPos -= cubemapCenter.xyz;
				worldRefDir = worldPos + worldRefDir * fa;
			}
			return worldRefDir;
		}
		inline float3 SamplerReflectProbe(UNITY_ARGS_TEXCUBE(tex),float3 refDir,float roughness,float4 hdr)
		{
			roughness = roughness * (1.7 - 0.7 * roughness);
			float mip = roughness * 6;
			float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex,refDir,mip);
			return DecodeHDR(rgbm,hdr);
		}
		//计算间接光镜面反射
		inline float3 ComputeIndirectSpecular(float3 refDir,float3 worldPos,float roughness,float occlusion)
		{
			float3 specular = 0;
			float3 refDir1 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
			float3 ref1 = SamplerReflectProbe(UNITY_PASS_TEXCUBE(unity_SpecCube0),refDir1,roughness,unity_SpecCube0_HDR);
			UNITY_BRANCH
			if(unity_SpecCube0_BoxMin.w < 0.99999)
			{
				float3 refDir2 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube1_ProbePosition,unity_SpecCube1_BoxMin,unity_SpecCube1_BoxMax);
				float3 ref2 = SamplerReflectProbe(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0),refDir2,roughness,unity_SpecCube1_HDR);

				specular = lerp(ref2,ref1,unity_SpecCube0_BoxMin.w);
			}
			else
			{
				specular = ref1;
			}
			return specular * occlusion;
		}

		inline float3 FakeComputeIndirectSpecular(float3 refDir,float3 worldPos,float roughness,float occlusion)
		{
			float3 specular = 0;
			float3 refDir1 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
			roughness = roughness * (1.7 - 0.7 * roughness);
			float mip = roughness * 6;
			float4 rgbm =  texCUBElod(_CubeMap,float4(refDir1,mip + _CubeMapLODBaseLvl));
			rgbm.rgb = IsGammaSpace() ? GammaToLinearSpace(rgbm.rgb) : rgbm.rgb;
			float3 ref1 = DecodeHDR(rgbm,unity_SpecCube0_HDR);
			specular = rgbm;
			
			return specular * occlusion;
		}

		inline float ComputeSmithJointGGXVisibilityTerm(float nl,float nv,float roughness)
		{
			float ag = roughness * roughness;
			float lambdaV = nl * (nv * (1 - ag) + ag);
			float lambdaL = nv * (nl * (1 - ag) + ag);
			
			return 0.5f/(lambdaV + lambdaL + 1e-5f);
		}
		inline float ComputeGGXTerm(float nh,float roughness)
		{
			float a = roughness * roughness;
			float a2 = a * a;
			float d = (a2 - 1.0f) * nh * nh + 1.0f;
			return a2 * UNITY_INV_PI / (d * d + 1e-5f);
		}
		inline float3 ComputeFresnelTerm(float3 F0,float cosA)
		{
			return F0 + (1 - F0) * pow(1 - cosA, 5);
		}
		inline float3 ComputeDisneyDiffuseTerm(float nv,float nl,float lh,float roughness,float3 baseColor)
		{
			float Fd90 = 0.5f + 2 * roughness * lh * lh;
			return baseColor * UNITY_INV_PI * (1 + (Fd90 - 1) * pow(1-nl,5)) * (1 + (Fd90 - 1) * pow(1-nv,5));
		}
		inline float3 ComputeFresnelLerp(float3 c0,float3 c1,float cosA)
		{
			float t = pow(1 - cosA,5);
			return lerp(c0,c1,t);
		}

	ENDCG
	SubShader
	{
		Tags{"Queue"="Geometry+20" "RenderType" = "Opaque"}


		//渲染X光效果的Pass
		Pass
		{
			Blend SrcAlpha One
			ZWrite Off
			ZTest Greater
 
			CGPROGRAM
			#include "Lighting.cginc"
			fixed4 _XRayColor;

			float _UseXRay;
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : normal;
				float3 viewDir : TEXCOORD0;
			};
 
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.viewDir = ObjSpaceViewDir(v.vertex);
				o.normal = v.normal;
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(i.viewDir);
				float rim = 1 - dot(normal, viewDir);

				float lp = 1;
				lp *= lerp(0, 1, _UseXRay);				
				_XRayColor.a *= lp;

				return _XRayColor * rim;
			}
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

		pass
		{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma vertex vert
			#pragma fragment frag



			//float4 _Color;
			sampler2D _AlbedoMap;
			float4 _AlbedoMap_ST;
			sampler2D _MaskMap;
			sampler2D _NormalMap;
			sampler2D _Channel;
			float4 _Dey1;
			float4 _GlowColor;
			//sampler2D _OcclusionMap;
			float _Metallic;
			float _Roughness;
			float _AO;
			float4 _BackLightColor;
			float _Power;
			float _SpecularPower;
			float _FresnelScale;
			float _FresnelSize;			
			float4 _FresnelColor;
			float4 _MaxColor;
			
			//float _BumpScale;
			//float4 _EmissionColor;
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
				float4 ambientOrLightmapUV : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
				SHADOW_COORDS(5) 
				UNITY_FOG_COORDS(6) 
			};

			v2f vert(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_AlbedoMap);

				float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent);
				float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

				o.ambientOrLightmapUV = VertexGI(v.texcoord1,v.texcoord2,worldPos,worldNormal);

				o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//世界坐标
				float3 albedo = tex2D(_AlbedoMap,i.uv).rgb;//反照率 * _Color.rgb
				albedo = IsGammaSpace() ? GammaToLinearSpace(albedo) : albedo;
				
				float4 mask = tex2D(_MaskMap,i.uv);
				mask.rgb = IsGammaSpace() ? GammaToLinearSpace(mask.rgb) : mask.rgb;
				float2 metallicGloss = mask.gb;
				float metallic = metallicGloss.x * _Metallic * mask.a;//金属度
				float roughness = (1 -(1 - metallicGloss.y) * _Roughness * mask.a) ;//粗糙度
				float occlusion = mask.r * _AO;//环境光遮挡
				// float occlusion = 0;
				float3 normalTangent = UnpackNormal(tex2D(_NormalMap,i.uv));
				float3 channel = tex2D(_Channel,i.uv);
				channel = IsGammaSpace() ? GammaToLinearSpace(channel) : channel;
				float bChannel = channel.z;
				albedo = lerp(albedo , _Dey1.rgb , channel.r);
				//normalTangent.xy *= _BumpScale;
				normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy,normalTangent.xy)));
				float3 worldNormal = normalize(float3(dot(i.TtoW0.xyz,normalTangent),
									dot(i.TtoW1.xyz,normalTangent),dot(i.TtoW2.xyz,normalTangent)));

				float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				float3 backLightDir = float3(-lightDir.x,lightDir.y,-lightDir.z);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 refDir = reflect(-viewDir,worldNormal);


				UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

				float3 floatDir = normalize(lightDir + viewDir);
				float3 backfloatDir = normalize(backLightDir + viewDir);
				float nv = saturate(dot(worldNormal,viewDir));
				float nl = saturate(dot(worldNormal,lightDir));
				float backnl = saturate(dot(worldNormal,backLightDir));
				float nh = saturate(dot(worldNormal,floatDir));
				float backnh = saturate(dot(worldNormal,backfloatDir));
				float lv = saturate(dot(lightDir,viewDir));
				float backlv = saturate(dot(backLightDir,viewDir));
				float lh = saturate(dot(lightDir,floatDir));
				float backlh = saturate(dot(backLightDir,backfloatDir));

				float3 specColor = lerp(LX_ColorSpaceDielectricSpec.rgb,albedo,metallic);
				float oneMinusReflectivity = (1- metallic) * LX_ColorSpaceDielectricSpec.a;
				float3 diffColor = albedo * oneMinusReflectivity;
				float3 indirectDiffuse = ComputeIndirectDiffuse(i.ambientOrLightmapUV,occlusion);
				//float3 indirectSpecular = ComputeIndirectSpecular(refDir,worldPos,roughness,occlusion);
				float3 indirectSpecular = FakeComputeIndirectSpecular(refDir,worldPos,roughness,occlusion);//texCUBE(_CubeMap,refDir).rgb * occlusion;
				
				float grazingTerm = saturate((1 - roughness) + (1-oneMinusReflectivity));
				indirectSpecular *= ComputeFresnelLerp(specColor,grazingTerm,nv);
				indirectDiffuse *= diffColor;

				float V = ComputeSmithJointGGXVisibilityTerm(nl,nv,roughness);
				float D = ComputeGGXTerm(nh,roughness);
				float3 F = ComputeFresnelTerm(specColor,lh);

				float backV = ComputeSmithJointGGXVisibilityTerm(backnl,nv,roughness);
				float BackD = ComputeGGXTerm(backnh,roughness);
				float3 backF = ComputeFresnelTerm(specColor,backlh);

				float3 specularTerm = V * D * F;
				float3 backSpecularTerm = backV * BackD *backF;

				float3 diffuseTerm = ComputeDisneyDiffuseTerm(nv,nl,lh,roughness,diffColor);
				float3 backDiffuseTerm = ComputeDisneyDiffuseTerm(nv,backnl,backlh,roughness,diffColor);

				//float fresnelNode = (0.0 + _SideLightScale * pow(1.0 - nv,5.0));
				//float3 sideColor = (saturate( ( (0.0 + (( atten * 1.3 ) - 0.4) * (1.0 - 0.0) / (1.0 - 0.4)) * fresnelNode * _SideLightColor ) )).rgb;
				float3 fresnelCol = (pow(1 - dot(worldNormal,viewDir), _FresnelSize)) * _FresnelColor.rgb * _FresnelScale;
				//float backFresnelNode = (0.0 + _SideLightScale * pow(1.0 - nv,5.0));
				//float3 backFideColor = (saturate( ( (0.0 + (( atten * 1.3 ) - 0.4) * (1.0 - 0.0) / (1.0 - 0.4)) * backFresnelNode * _SideLightColor ) )).rgb;
				float3 backColor = ((backDiffuseTerm + backSpecularTerm) * _BackLightColor.rgb *backnl ) * _Power ;
				float3 color = (UNITY_PI * (diffuseTerm + specularTerm * _SpecularPower) * _LightColor0.rgb * nl 
								+ indirectDiffuse + indirectSpecular) * atten + backColor ;// + emission;
				color = IsGammaSpace() ? LinearToGammaSpace(color) : color;
				color = clamp(color,float3(0,0,0),_MaxColor.rgb);

				// color.rgb += _GlowColor * bChannel;
				//使用saturate约束一下，防止菲涅尔反射出现白色光点
				color.rgb += _GlowColor * bChannel + float3(saturate(fresnelCol.r),saturate(fresnelCol.g),saturate(fresnelCol.b));
				UNITY_APPLY_FOG(i.fogCoord, color.rgb);
				
				return float4(color,1);
			}

			ENDCG
		}

	}
	FallBack "VertexLit"
}
