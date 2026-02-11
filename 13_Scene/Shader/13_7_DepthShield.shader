Shader "B/13_7_DepthShield_Merged"
{
    Properties
    {
        [Header(Base Settings)]
        _MainTex ("基础纹理 (Alpha通道作为遮罩)", 2D) = "white" {}
        [HDR]_BaseColor("主体颜色", Color) = (1, 1, 1, 1)
        _BaseAlpha("全局透明度", Range(0, 1)) = 1.0

        [Header(Ramp Settings)]
        [NoScaleOffset] _RampTex("渐变贴图 (Ramp)", 2D) = "white" {}
        _RampIntensity("渐变强度", Range(0, 5)) = 1.0

        [Header(Normal and Distortion)]
        [Normal] _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(0, 2)) = 1.0
        _DistortionStrength("扭曲强度", Range(0, 0.5)) = 0.05
        _FlowSpeed("流速 (XY:法线, ZW:主贴图)", Vector) = (0.1, 0.1, 0, 0)

        [Header(Dissolve Settings)]
        [NoScaleOffset] _DissolveTex("溶解噪声图", 2D) = "white" {}
        _DissolveAmount("溶解进度 (0-1)", Range(0, 1)) = 0.0
        _DissolveScale("噪声缩放", Float) = 1.0
        _DissolveNoiseStrength("噪声影响强度", Range(0, 1)) = 0.3
        _DissolveEdgeWidth("溶解边缘宽度", Range(0, 1.0)) = 0.1
        _DissolveEdgeHardness("溶解边缘硬度", Range(0, 1.0)) = 0.5
        [HDR] _DissolveEdgeColor("溶解边缘颜色", Color) = (2, 0.5, 0, 1)
        _DissolveEdgeIntensity("溶解边缘强度", Range(0, 20)) = 1.0

        [Header(Fresnel Parameters)]
        _Fresnel_Fade("菲涅尔衰减 (Pow)", Range(0.1, 10)) = 2.0
        
        [Header(Depth Intersection)]
        _DepthEdgeSize("交界线宽度 (单位:米)", Range(0, 5)) = 0.5
        _DepthPow("交界线软硬度 (Pow)", Range(0, 5)) = 1.0
        _BackDepthMulti("背面深度宽度修正", Range(1, 5)) = 1.5

        [Header(Render Options)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("混合源", Float) = 5 
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("混合目标", Float) = 10 
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("剔除模式", Float) = 0 
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent" 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite Off
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_MainTex);     SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);   SAMPLER(sampler_NormalTex);
            TEXTURE2D(_RampTex);     SAMPLER(sampler_RampTex);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalTex_ST;
                float4 _FlowSpeed;
                half4  _BaseColor;
                half4  _DissolveEdgeColor;
                half   _BaseAlpha;
                half   _RampIntensity;
                half   _NormalScale;
                half   _DistortionStrength;
                half   _Fresnel_Fade;
                float  _DepthEdgeSize;
                float  _DepthPow;
                float  _BackDepthMulti;
                float  _DissolveAmount;
                float  _DissolveScale;
                float  _DissolveNoiseStrength;
                float  _DissolveEdgeWidth;
                float  _DissolveEdgeHardness;
                float  _DissolveEdgeIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;  
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 texcoord   : TEXCOORD0;
            };

            struct Varyings
            {  
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float4 uv         : TEXCOORD0; 
                float4 screenPos  : TEXCOORD3; 
                half3  normalWS   : TEXCOORD4;
                half4  tangentWS  : TEXCOORD5;
                half3  bitangentWS: TEXCOORD6;
                float3 positionOS : TEXCOORD7; 
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;
                o.positionOS = v.positionOS.xyz;
                o.screenPos = ComputeScreenPos(o.positionCS);

                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = half3(normInputs.normalWS);
                o.tangentWS = half4(normInputs.tangentWS, v.tangentOS.w);
                o.bitangentWS = half3(normInputs.bitangentWS);

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + _Time.y * _FlowSpeed.zw;
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex) + _Time.y * _FlowSpeed.xy;
                
                return o;
            }

            half4 frag (Varyings i, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                // 1. 局部空间溶解逻辑
                float2 dissolveUV = i.positionOS.xz * _DissolveScale;
                float noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
                
                float mappedAmount = lerp(-0.8, 1.2, _DissolveAmount);
                float dissolveValue = (noise * _DissolveNoiseStrength) - i.positionOS.y - mappedAmount;
                
                clip(dissolveValue);

                // --- 强化发光逻辑：引入 _DissolveEdgeIntensity 参数 ---
                float edgeStart = _DissolveEdgeWidth;
                float edgeEnd = _DissolveEdgeWidth * _DissolveEdgeHardness;
                float edgeMask = smoothstep(edgeStart, edgeEnd, dissolveValue);
                // 颜色计算：Mask * 颜色 * Alpha倍率 * 强度系数
                half3 edgeColor = edgeMask * _DissolveEdgeColor.rgb * _DissolveEdgeColor.a * _DissolveEdgeIntensity;

                // 2. 获取扭曲法线
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.zw), _NormalScale);
                
                // 3. 深度交界计算
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float2 distortion = normalTS.xy * _DistortionStrength;
                float2 distortedScreenUV = screenUV + distortion;

                float rawDepth = SampleSceneDepth(distortedScreenUV);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float surfaceEyeDepth = i.screenPos.w;
                float depthDiff = sceneEyeDepth - surfaceEyeDepth;
                
                float currentEdgeSize = isFrontFace ? _DepthEdgeSize : (_DepthEdgeSize * _BackDepthMulti);
                float intersection = 1.0 - saturate(depthDiff / max(0.0001, currentEdgeSize));
                intersection = pow(max(0, intersection), (half)_DepthPow);

                // 4. 菲涅尔计算
                half3 worldNormal = normalize(i.normalWS);
                half3 worldTangent = normalize(i.tangentWS.xyz);
                half3 worldBitangent = normalize(i.bitangentWS);
                half3x3 TBN = half3x3(worldTangent, worldBitangent, worldNormal);
                half3 N = normalize(mul(normalTS, TBN));
                N = N * (isFrontFace ? 1.0h : -1.0h);

                half3 V = SafeNormalize(half3(GetCameraPositionWS() - i.positionWS));
                half ndotv = saturate(dot(N, V));
                half fresnelTerm = pow(1.0h - ndotv, _Fresnel_Fade);

                // 5. 合并 Mask 并采样 Ramp
                half combinedMask = saturate(max(intersection, fresnelTerm));
                half3 rampColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(combinedMask, 0.5)).rgb;
                
                // 6. 采样基础纹理
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy + distortion);

                // 7. 最终输出计算
                // 发光叠加：(基础色 * 渐变) + 强化后的溶解边缘色
                half3 finalRGB = (tex.rgb * _BaseColor.rgb * rampColor * _RampIntensity) + edgeColor;
                half finalAlpha = combinedMask * _BaseColor.a * tex.a * _BaseAlpha;

                if(!isFrontFace) finalRGB *= 0.8;

                return half4(finalRGB, finalAlpha);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}