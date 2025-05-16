
Shader "sw/character/ActorBlinnPhongNoiseClip"
{
	Properties
	{
		_AlbedoMap("AlbedoMap",2D) = "white"{}	//反照率
		//_NormalMap("NormalMap",2D) = "bump"{}//法线贴图
		_MaskMap("MaskMap（r金属度,g粗糙度，b空）",2D) = "white"{} //金属图，g通道存储金属度，b通道存储光滑度
		_Glow("Roughness 粗糙强度",Range(0,20)) = 0.5 //光滑强度
		_Metallic("Metallic 金属强度",Range(0,1)) = 1 //金属强度
		_Specular("Specular Color",Color) = (1,1,1,1)
		_Ambient("Ambient Color",Color) = (1,1,1,1)
		_FresnelSize ("FresnelSize 反射区域大小", Range(0, 10)) = 2.5
        _Amount ("_Amount 反射强度(值用0)", Range(0, 10)) = 0
        _FresnelColor ("FresnelColor 反射光的颜色", Color) = (0.983,1,0.438,1)
		[Toggle(RealLightMode)]_RealLightMode("实时光模式",Float) = 1
		_NoiseTex("Noise", 2D) = "white" {}
		_Threshold("Threshold(值用0)", Range(0.0, 1.01)) = 0
		_EdgeLength("Edge Length", Range(0.0, 0.2)) = 0.035
		[HDR]_EdgeColor("Edge Color", Color) = (9.5,1.9,0.5,1)
		//_CustomFakeLightColor("Custom Fake Light Color",Color) = (1,1,1,1)
		//_CustomFakeLightPower("Custom Fake Light Power",Float) = 1
		//_CustomFakeLightDir("Custom Fake Light Dir",vector) = (1,1,1,0) 
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"

	ENDCG
	SubShader
	{
		Tags{"Queue"="Geometry+20" "RenderType" = "Opaque"}
		pass
		{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma target 3.0

			//#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog
			#pragma multi_compile __ RealLightMode
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _AlbedoMap;
			float4 _AlbedoMap_ST;
			sampler2D _MaskMap;
			//sampler2D _NormalMap;
			float _Glow;
			float _Metallic;
			float4 _Specular;
			float4 _Ambient;
			uniform float _FresnelSize;
			uniform float _Amount;
			uniform float4 _FresnelColor;

			uniform float4 _CustomFakeLightColor;
			//uniform float _CustomFakeLightPower;
			uniform float4 _CustomFakeLightDir; 

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float _Threshold;
			float _EdgeLength;
			fixed4 _EdgeColor;

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
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				float2 uvNoiseTex : TEXCOORD4;
				//SHADOW_COORDS(5) 
				//UNITY_FOG_COORDS(6) 
			};

			v2f vert(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_AlbedoMap);
				o.uvNoiseTex = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 worldTangent = UnityObjectToWorldDir(v.tangent);
				half3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				//TRANSFER_SHADOW(o);
				//UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//世界坐标
				half3 albedo = tex2D(_AlbedoMap,i.uv).rgb;//反照率 * _Color.rgb
				//albedo = IsGammaSpace() ? GammaToLinearSpace(albedo) : albedo;
				half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half4 mask = tex2D(_MaskMap,i.uv);
				//mask.rgb = IsGammaSpace() ? GammaToLinearSpace(mask.rgb) : mask.rgb;
				half2 metallicGloss = mask.gb;
				half metallic = metallicGloss.x * _Metallic;//金属度
				half roughness = max(0.1,metallicGloss.y * _Glow) ;//粗糙度
				half3 normalTangent = half3(0,0,1);//UnpackNormal(tex2D(_NormalMap,i.uv));
				half3 lightDir;//
				half3 lightColor;
				#if RealLightMode
					lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
					lightColor = _LightColor0.rgb;
				#else
					lightDir = normalize(-_CustomFakeLightDir.xyz);//normalize(_CustomFakeLightDir.xyz - worldPos);
					lightColor = _CustomFakeLightColor.rgb;// * _CustomFakeLightPower;
				#endif
				half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz,normalTangent),
									dot(i.TtoW1.xyz,normalTangent),dot(i.TtoW2.xyz,normalTangent)));

				float3 halfDir = normalize(lightDir + viewDir);
				float d = max(0,dot(halfDir , worldNormal));
				float3 spec = lightColor * _Specular.rgb * max(0, pow(d,roughness)) * metallic;
				float3 diff = lightColor * max(0,dot(lightDir,worldNormal));
				float3 fresnelCol = (pow(1 - max(0,dot(worldNormal,viewDir)),_FresnelSize) * _FresnelColor.rgb * _Amount);
				float4 color;
				color.rgb =(spec + diff + _Ambient.rgb) * albedo + fresnelCol;

				fixed cutout = tex2D(_NoiseTex, i.uvNoiseTex).r;
				clip(cutout - _Threshold);
				
				if(cutout - _Threshold < _EdgeLength)
					return _EdgeColor;
				//float value = step(0,cutout - _Threshold < _EdgeLength);
				//color.rgb = lerp(color.rgb,_EdgeColor,value);
				//color.rgb = lightDir;
				color.a = 1;
				return color;
			}

			ENDCG
		}
	}
	FallBack "VertexLit"
}
