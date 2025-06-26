Shader "10_08_GlassReflectMatcap"
{
    Properties
    {
        _BaseTex("Base Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _GlassAlpha("Glass Alpha", Range(0, 1)) = 1.0

        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalDistort("Normal Distortion Intensity", Range(0, 2)) = 1.0

        _Matcap("Matcap", 2D) = "white" {}
        _MatcapIntensity("Matcap Intensity", Range(0, 1.5)) = 1

        [NoScaleOffset]_ReflectCube("Reflection Cubemap", CUBE) = "" {}
        _ReflectIntensity("Reflection Intensity", Range(0, 1)) = 0.5

        _OpacityMu("Opacity Multiply", Range(0, 10)) = 1

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1        
        

    }

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {


            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend[_SrcBlend][_DstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct FragmentInput
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 tangentWS : TANGENT;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseTex_ST;
                float4 _NormalMap_ST;
                float4 _BaseColor;

                float _NormalDistort;
                float _GlassAlpha;
                float _MatcapIntensity;
                float _ReflectIntensity;
                float _OpacityMu;
            CBUFFER_END

            TEXTURE2D(_BaseTex);          SAMPLER(sampler_BaseTex);
            TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
            TEXTURE2D(_Matcap);           SAMPLER(sampler_Matcap);
            TEXTURECUBE(_ReflectCube);    SAMPLER(sampler_ReflectCube);

            FragmentInput vert(VertexInput v)
            {
                FragmentInput o;

                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;

                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normInputs.normalWS;
                o.tangentWS = float4(normInputs.tangentWS, v.tangentOS.w);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseTex);
                return o;
            }

            half4 frag(FragmentInput i) : SV_Target
            {
                // 构建切线空间转世界空间矩阵
                float3 t = normalize(i.tangentWS.xyz);
                float3 n = normalize(i.normalWS);
                float3 b = cross(n, t) * i.tangentWS.w;
                float3x3 tangentToWorld = float3x3(t, b, n);

                // 法线扰动控制
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv), _NormalDistort);
                half3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);

                // 观察方向和反射方向
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 reflectDir = reflect(-viewDir, normalWS);

                // 主颜色贴图
                half4 baseCol = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv) * _BaseColor;

                // Matcap 高光（近似模拟）
                float3 normalVS = mul(UNITY_MATRIX_V, float4(normalWS, 0.0)).xyz;
                float3 positionVS = normalize(mul(UNITY_MATRIX_MV, float4(i.positionWS, 1.0)).xyz);
                float3 crossVec = cross(normalVS, positionVS);
                float2 matcapUV = float2(-crossVec.y, crossVec.x) * 0.5 + 0.5;
                half4 matcapCol = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, matcapUV) * _MatcapIntensity;

                // 反射贴图
                half4 reflectCol = SAMPLE_TEXTURECUBE(_ReflectCube, sampler_ReflectCube, reflectDir) * _ReflectIntensity;

                // 厚度（影响 alpha）
                float VDotN = dot(viewDir, normalWS);
                float Thickness = 1 - smoothstep(0.0, 1.0, VDotN);

                // Alpha 透明控制
                float alpha = saturate(max(matcapCol.x, Thickness) * _OpacityMu) * _GlassAlpha;

                // 颜色组合：Base受 _BaseColor 调制，其他不受影响
                half3 combinedColor = baseCol.rgb * _BaseColor.rgb 
                                    + matcapCol.rgb 
                                    + reflectCol.rgb;

                return float4(combinedColor, alpha);

            }

            ENDHLSL
        }
    }
}
