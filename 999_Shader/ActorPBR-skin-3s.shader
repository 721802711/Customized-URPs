Shader "WL3/Actor/Darren/ActorPBR-skin-3s"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "white" {}
		// _BaseColor("BaseColor", Color) = (0,0,0,0)
		_NormalMap("NormalMap", 2D) = "bump" {}
		_DetailMap("DetailMap", 2D) = "white" {}
		_NoiseBump("NoiseBump", Range( 0 , 2)) = 1
		_MaskMap("MaskMap,(a Special Area)", 2D) = "white" {}
		// _3SColorEmissionBack("3SColor-EmissionBack", Color) = (0,1,0.1724138,0)
		_CubeMap("cubemap",Cube) = "sky"{}
		_CubeMapLODBaseLvl("cubemap LOD baselvl",Range(0,10)) = 7
		_BackLightColor("BackLightColor 背光颜色",Color) = (1,1,1,1)
		_Power("BackLightPower 背光强度",Range(0,10)) = 1
		[Toggle] _UseXRay ("Use Xray?", Float ) = 0
		_XRayColor("XRay Color", Color) = (1,1,1,1)
    }
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		#define WS_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
		samplerCUBE _CubeMap;
		float _CubeMapLODBaseLvl;
		float4 _BackLightColor;
		float _Power;

		half3 WS_ShadeSH9 (half4 normal)
		{
			// Linear + constant polynomial terms
			half3 res = SHEvalLinearL0L1 (normal);
		    // Quadratic polynomials
			res += SHEvalLinearL2 (normal);
			return res;
		}
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
				ambientOrLightmapUV.rgb += WS_ShadeSH9(half4(worldNormal,1));
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

				// indirectDiffuse = 0;
			#endif
			#ifdef LIGHTMAP_ON
				indirectDiffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,ambientOrLightmapUV.xy));
			#endif
			#ifdef DYNAMICLIGHTMAP_ON
				indirectDiffuse += DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap,ambientOrLightmapUV.zw));
			#endif

			return indirectDiffuse * occlusion;
		}
		inline half WS_OneMinusReflectivityFromMetallic(half metallic)
		{
			half oneMinusDielectricSpec = WS_ColorSpaceDielectricSpec.a;
			return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
		}
		inline half3 WS_DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
		{
			specColor = lerp (WS_ColorSpaceDielectricSpec.rgb, albedo, metallic);
			oneMinusReflectivity = WS_OneMinusReflectivityFromMetallic(metallic);
			return albedo * oneMinusReflectivity;
		}
	
		inline half3 WS_PreMultiplyAlpha (half3 diffColor, half alpha, half oneMinusReflectivity, out half outModifiedAlpha)
		{
			#if defined(_ALPHAPREMULTIPLY_ON)
				diffColor *= alpha;
	
				#if (SHADER_TARGET < 30)
					outModifiedAlpha = alpha;
				#else
					outModifiedAlpha = 1-oneMinusReflectivity + alpha*oneMinusReflectivity;
				#endif
			#else
				outModifiedAlpha = alpha;
			#endif
			return diffColor;
		}
	
		half WS_DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
		{
			half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
			// Two schlick fresnel term
			half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
			half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));

			return lightScatter * viewScatter;
		}
	    inline half3 WS_DisneyDiffuseTerm(half nv,half nl,half lh,half roughness,half3 baseColor)
		{
			half Fd90 = 0.5f + 2 * roughness * lh * lh;
			return baseColor * UNITY_INV_PI * (1 + (Fd90 - 1) * pow(1-nl,5)) * (1 + (Fd90 - 1) * pow(1-nv,5));
		}
		float WS_PerceptualRoughnessToRoughness(float perceptualRoughness)
		{
			return perceptualRoughness * perceptualRoughness;
		}
		inline float WS_SmithJointGGXVisibilityTerm (float NdotL, float NdotV, float roughness)
		{
			#if 0
				half a          = roughness;
				half a2         = a * a;

			    half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
				half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);
				return 0.5f / (lambdaV + lambdaL + 1e-5f);                                                
			#else
				float a = roughness;
				float lambdaV = NdotL * (NdotV * (1 - a) + a);
				float lambdaL = NdotV * (NdotL * (1 - a) + a);

			#if defined(SHADER_API_SWITCH)
				return 0.5f / (lambdaV + lambdaL + 1e-4f); // work-around against hlslcc rounding error
			#else
				return 0.5f / (lambdaV + lambdaL + 1e-5f);
			#endif

			#endif
		}

		inline half3 WS_FresnelTerm (half3 F0, half cosA)
		{
			half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
			return F0 + (1-F0) * t;
		}

		inline half3 WS_FresnelLerp (half3 F0, half3 F90, half cosA)
		{
			half t = Pow5(1 - cosA);   // ala Schlick interpoliation
			return lerp (F0, F90, t);
		}

		inline float WS_GGXTerm (float NdotH, float roughness)
		{
			float a2 = roughness * roughness;
			float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
			return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
                                            // therefore epsilon is smaller than what can be represented by half
		}
		half4 WS_BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,float3 normal, float3 viewDir,half3 dir,half3 lightColor, half3 diffuse, half3 specular,half atten)
		{
			float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
			float3 halfDir = Unity_SafeNormalize (float3(dir) + viewDir);

			#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

			#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
				half shiftAmount = dot(normal, viewDir);
				normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;

				float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
			#else
			    half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
			#endif

		    float nl = saturate(dot(normal, dir));
		    float nh = saturate(dot(normal, halfDir));

			half lv = saturate(dot(dir, viewDir));
			half lh = saturate(dot(dir, halfDir));

			half diffuseTerm = WS_DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

			float roughness = WS_PerceptualRoughnessToRoughness(perceptualRoughness);
			#if UNITY_BRDF_GGX
				roughness = max(roughness, 0.002);
				float V = WS_SmithJointGGXVisibilityTerm (nl, nv, roughness);
				float D = WS_GGXTerm (nh, roughness);
			#else
				half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
				half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
			#endif

			float specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later
			//return half4(viewDir,1);

			specularTerm = max(0, specularTerm * nl);
			#if defined(_SPECULARHIGHLIGHTS_OFF)
				specularTerm = 0.0;
			#endif

			half surfaceReduction;
			//#ifdef UNITY_COLORSPACE_GAMMA
			//	surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
			//#else
				surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
			//#endif

			//backlight
			half3 backLightDir = half3(-dir.x,dir.y,-dir.z);
			half3 backHalfDir = normalize(backLightDir + viewDir);
			float backnl = saturate(dot(normal, backLightDir));
			half backlh = saturate(dot(backLightDir,backHalfDir));
			half backnh = saturate(dot(normal,backHalfDir));

			float backV = WS_SmithJointGGXVisibilityTerm (backnl, nv, roughness);
			float BackD = WS_GGXTerm (nh, roughness);
			half3 backF = WS_FresnelTerm(specColor,backlh);
			half3 backSpecularTerm = backV * BackD *backF;
			half3 backDiffuseTerm = WS_DisneyDiffuseTerm(nv,backnl,backlh,perceptualRoughness,diffColor);

			specularTerm *= any(specColor) ? 1.0 : 0.0;
			//half3 backColor = (backDiffuseTerm + backSpecularTerm) * _BackLightColor.rgb * backnl * _Power;
			half3 backColor = (backDiffuseTerm + backSpecularTerm) * _BackLightColor.rgb * backnl * _Power;
			half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
			half3 color =   (diffColor * (diffuse + lightColor * diffuseTerm)
                    + specularTerm * lightColor * WS_FresnelTerm (specColor, lh)
                    + surfaceReduction * specular * WS_FresnelLerp (specColor, grazingTerm, nv)) * atten + backColor;
			//half3 color =   diffColor * (diffuse + lightColor * diffuseTerm)
   //                 + specularTerm * lightColor * WS_FresnelTerm (specColor, lh)
   //                 + surfaceReduction * specular * WS_FresnelLerp (specColor, grazingTerm, nv);
			return half4(color, 1);
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
			
			return specular * occlusion * 10;
		}
		ENDCG
    SubShader
    {
        Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+20"}

		

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

        Pass
        {
			Tags{"LightMode" = "ForwardBase"}
					Cull Back
		ZTest LEqual
            CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			uniform sampler2D _NormalMap;
			uniform half4 _NormalMap_ST;
			uniform sampler2D _DetailMap;
			uniform half4 _DetailMap_ST;
			uniform half _NoiseBump;
			uniform sampler2D _MaskMap;
			uniform half4 _MaskMap_ST;
			// uniform float4 _BaseColor;
			uniform sampler2D _Albedo;
			uniform half4 _Albedo_ST;
			uniform float4 _3SColorEmissionBack;

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
                float2 uv_texcoord : TEXCOORD0;
                float4 pos : SV_POSITION;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				half4 ambientOrLightmapUV : TEXCOORD4;
				SHADOW_COORDS(5) 
				UNITY_FOG_COORDS(6) 
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv_texcoord = TRANSFORM_TEX(v.texcoord,_Albedo);
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
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

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
				half3 tex2DNode12 = UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) );
				half4 color93 = half4(0.2158605,0.2158605,1,0);
				float2 uv_DetailMap = i.uv_texcoord * _DetailMap_ST.xy + _DetailMap_ST.zw;
				half4 tex2DNode60 = tex2D( _DetailMap, uv_DetailMap );
				tex2DNode60.rgb = IsGammaSpace() ? GammaToLinearSpace(tex2DNode60.rgb) : tex2DNode60.rgb;
				float2 uv_MaskMap = i.uv_texcoord * _MaskMap_ST.xy + _MaskMap_ST.zw;
				half4 tex2DNode21 = tex2D( _MaskMap, uv_MaskMap );
				half4 break95 = lerp( color93 , tex2DNode60 , saturate( ( _NoiseBump * ( 1.0 - ( ( tex2DNode21.g + 0.0 ) * 2.0 ) ) ) ));				
				half3 appendResult78 = (half3(( tex2DNode12.r + break95.r ) , ( break95.g + tex2DNode12.g ) , ( tex2DNode12.b + tex2DNode60.b )));
				half3 normal = normalize( ( ( 2.0 * appendResult78 ) + -0.43 ) );				
				float2 uv_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
				// half4 temp_output_11_0 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
				half4 temp_output_11_0 = tex2D( _Albedo, uv_Albedo );
				temp_output_11_0.rgb = IsGammaSpace() ? GammaToLinearSpace(temp_output_11_0.rgb) : temp_output_11_0.rgb;
				half3 Albedo = temp_output_11_0.rgb;
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//世界坐标
				float3 ase_worldPos = worldPos;
				half3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
				half3 ase_worldNormal = normalize(half3(dot(i.TtoW0.xyz,normal),dot(i.TtoW1.xyz,normal),dot(i.TtoW2.xyz,normal)));//WorldNormalVector( i, half3( 0, 0, 1 ) );
				half dotResult32 = dot( ase_worldlightDir , ase_worldNormal );
				_3SColorEmissionBack = float4(0.58431,0.4157, 0.3294, 1);
				half3 emission = (0.5 * temp_output_11_0 * _3SColorEmissionBack ).rgb;
				half Metallic = 0;
				half Smoothness = ( tex2DNode21.r * 1.15 );
				half Occlusion = tex2DNode21.b;
				half3 Alpha = 1;
				UNITY_LIGHT_ATTENUATION(atten,i,worldPos);
				half3 worldlightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half3 indirectDiffuse = ComputeIndirectDiffuse(i.ambientOrLightmapUV, Occlusion);
				half oneMinusReflectivity;
				half3 specColor;
				Albedo = WS_DiffuseAndSpecularFromMetallic (Albedo, Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);
				half outputAlpha;
				Albedo = WS_PreMultiplyAlpha (Albedo, Alpha, oneMinusReflectivity, /*out*/ outputAlpha);
				half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz,normal),dot(i.TtoW1.xyz,normal),dot(i.TtoW2.xyz,normal)));
				half3 refDir = reflect(-viewDir, worldNormal);
				half3 indirectSpecular = FakeComputeIndirectSpecular(refDir,worldPos,(1.0 - Smoothness), Occlusion);
				indirectSpecular = lerp(indirectSpecular , half3(0,0,0) , tex2DNode21.a);
				half4 color = WS_BRDF1_Unity_PBS (Albedo, specColor, oneMinusReflectivity, Smoothness, ase_worldNormal, viewDir, worldlightDir, _LightColor0.rgb,indirectDiffuse, indirectSpecular, atten);	
				color.a = outputAlpha;
				UNITY_APPLY_FOG(i.fogCoord,color.rgb);
				color = color + half4(emission,1);
				color.rgb = IsGammaSpace() ? LinearToGammaSpace(color.rgb) : color.rgb;
				// color.rgb = i.ambientOrLightmapUV.rgb * Occlusion;
				return color;
            }
            ENDCG
        }
    }
	FallBack "VertexLit"
}
