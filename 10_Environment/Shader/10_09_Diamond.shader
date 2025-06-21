// 使用HLSL语法实现钻石Shader，使用双Pass渲染

Shader "B/10_09_Diamond"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Main Texture", 2D) = "white" {}
		_HeightMap("Height Map", 2D) = "white" {}

		[Header(POM)]
		_HeightScale("Height Scale", Range(0, 1.0)) = 0.02
		_Steps("POM Steps", Range(4, 64)) = 32

		[Header(Diamond)]
		[HDR] _RefratColor("Reflect Color", Color) = (1, 1, 1, 1)
		_RefratTex("Refractive Texture", Cube) = "white" {}
		_RefratIntensity("Refractive Intensity", Range(0, 5)) = 0.5
		_ReflectTex("Reflective Texture", Cube) = "white" {}
		[HDR] _ReflecColor("Reflec Color", Color) = (1, 1, 1, 1)
		_F_Power("F Power", Range(0, 20)) = 1
		_F_Intensity("F Intensity", Range(0, 5)) = 1
		_F_Bias("F Bias", float) = 0
		[HDR] _F_Color("F Color", Color) = (1, 1, 1, 1)

	}

	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

		LOD 100

        HLSLINCLUDE


        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

		CBUFFER_START(UnityPerMaterial)
			float4 _RefratColor, _ReflecColor, _F_Color;
			float _RefratIntensity;
			float _F_Power, _F_Intensity, _F_Bias;
			float _HeightScale;
			float _Steps;
		CBUFFER_END


		struct appdata
		{
			float4 positionOS : POSITION;
			float3 normalOS : NORMAL;
			float4 tangentOS : TANGENT;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 positionCS : SV_POSITION;
			float3 normalWS : NORMAL;
			float2 uv : TEXCOORD0;
			float3 viewDirWS : TEXCOORD1;
			float3 tangentWS : TEXCOORD2;
			float3 bitangentWS : TEXCOORD3;
		};

		TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
		TEXTURE2D(_HeightMap);                        SAMPLER(sampler_HeightMap);
		TEXTURECUBE (_RefratTex);              SAMPLER(sampler_RefratTex);
		TEXTURECUBE (_ReflectTex);              SAMPLER(sampler_ReflectTex);

        ENDHLSL


		Pass
		{

			// 第一个Pass用于实现折射效果
			Tags{ "LightMode" = "UniversalForward" }

			Blend One One
			Cull Back

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			float2 ParallaxOcclusionMapping(float2 uv, float3 viewDirTS, float heightScale, int maxSteps)
			{
				float layerDepth = 1.0 / maxSteps;
				float currentLayerDepth = 0.0;
				float2 deltaUV = viewDirTS.xy * heightScale / max(viewDirTS.z, 0.0001) / maxSteps;
				float2 currentUV = uv;
				float currentDepth = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, currentUV).r;

				// 固定循环次数，最多迭代 maxSteps 次
				[unroll(64)] // 你可以设置最大为 64
				for (int i = 0; i < 64; i++)
				{
					if (i >= maxSteps) break;

					if (currentLayerDepth >= currentDepth)
						break;

					currentUV -= deltaUV;
					currentDepth = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, currentUV).r;
					currentLayerDepth += layerDepth;
				}

				return currentUV;
			}


			v2f vert(appdata v)
			{
				v2f o;
					VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
					o.positionCS = PositionInputs.positionCS;
					float3 positionWS = PositionInputs.positionWS;

					VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS);
					o.normalWS = NormalInputs.normalWS;
					float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
					float3 bitangentWS = cross(o.normalWS, tangentWS) * v.tangentOS.w;

					o.viewDirWS = GetCameraPositionWS().xyz - positionWS;
					o.tangentWS = tangentWS;
					o.bitangentWS = bitangentWS;
					o.uv = v.uv;
				return o;
			}


			float4 frag(v2f i) : SV_Target
			{
				// 计算折射颜色
				half3 viewDirWS = normalize(i.viewDirWS);
				half3 normalWS = normalize(i.normalWS);



				float3x3 TBN = float3x3(normalize(i.tangentWS), normalize(i.bitangentWS), normalize(i.normalWS));
				float3 viewDirTS = mul(TBN, normalize(i.viewDirWS));

				// POM UV 偏移
				float2 offsetUV = ParallaxOcclusionMapping(i.uv, viewDirTS, _HeightScale, (int)_Steps);

				// 使用 POM 偏移后的 UV 采样贴图
				half4 MainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, offsetUV);

				// 折射逻辑保持不变
				half3 refractDir = reflect(-normalize(i.viewDirWS), normalize(i.normalWS));
				half Fre = 1 - saturate(dot(normalize(i.viewDirWS), normalize(i.normalWS)));
				Fre = max(pow(Fre, _F_Power), 0.000001) * _F_Intensity + _F_Bias;

				half4 Fre_Color = _F_Color * Fre;

				

				// 折射纹理与反射计算
				half4 refractColor = MainTexColor * _RefratColor;
				half4 refra = SAMPLE_TEXTURECUBE_LOD(_RefratTex, sampler_RefratTex, refractDir, 0);
				half4 reflect = SAMPLE_TEXTURECUBE_LOD(_RefratTex, sampler_RefratTex, refractDir, 0) * Fre;


				half4 finalColor = refra * reflect;
				finalColor += refractColor;

				return finalColor + Fre_Color;
			}
			ENDHLSL

		}


		Pass
		{
			// 第二个Pass用于实现背面剔除
			Tags{ "LightMode" = "SRPDefaultUnlit" }

			Blend off
			Cull front


			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			v2f vert(appdata v)
			{
				v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS; 
                float3 positionWS = PositionInputs.positionWS;  

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS);
                o.normalWS = NormalInputs.normalWS;

				o.viewDirWS = GetCameraPositionWS().xyz - positionWS;
				o.uv = v.uv;

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				// 计算折射颜色
				half3 viewDirWS = normalize(i.viewDirWS);
				half3 normalWS = normalize(i.normalWS);

				half3 refractDir = reflect( -viewDirWS, normalWS);



				half4 refra = SAMPLE_TEXTURECUBE_LOD(_RefratTex, sampler_RefratTex, refractDir, 0) * _RefratIntensity;
				half4 reflect = SAMPLE_TEXTURECUBE_LOD(_ReflectTex, sampler_ReflectTex, refractDir, 0);

				half4 finalColor = refra * reflect * _RefratColor; 
				return finalColor;
			}

			ENDHLSL
		}

	}

}