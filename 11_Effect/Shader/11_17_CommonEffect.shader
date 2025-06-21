
Shader "B/11_17_CommonEffect" {
    Properties {
        _MainTex ("Main Tex", 2D) = "white" {}
        _SecondaryTex ("Secondary Tex", 2D) = "white" {}


        //[Header(主纹理滚动动画)]
    	[Header(MainTex Scroll Animation)]
        _MainTexUVAni ("主纹理动画速度 (XY 主纹理 UV，ZW 副纹理 UV)", Vector) = (0,0,0,0)

        _DistortMap ("Distort Tex", 2D) = "white" {}
        _SecondaryDistortMap ("Secondary Dissolve Tex", 2D) = "white" {}
        _MaskMap ("Mask Tex", 2D) = "white" {}

        _DistortFactor ("扭曲强度", Range(0,0.5)) = 0.15
        _UVAnination ("Distort Ani", Vector) = (0,0,0,0)

        [HDR]_TintColor("Color", Color) = (1,1,1,1)
        _ColorFactor("Color Factor", Range(0,5)) = 1.5

        _DissolveFactor("dissolve factor", Range(0,1.01)) = 0.5
        _DissolveEdge("dissolve Edge", Range(0,0.3)) = 0.1
        [HDR]_DissolveEdgeColor("dissolve Edge Color", color) = (1,1,1,1)
        _DissolveMap ("Dissolve Tex", 2D) = "white" {}

        [Enum(Off,4,On,0)]_Ztest("Z Test",Float)=4

        [Toggle(ENABLE_SECONDARYTEX)] _EnableSecondaryTex ("贴图2", Float) = 0
        [Toggle(ENABLE_DISTORT)] _Distort ("扭曲", Float) = 0
        [Toggle] _Mask ("遮罩", Float) = 0
        [Toggle(ENABLE_DISSOLVE)] _Dissolve ("Dissolve", Float) = 0
        [Toggle(ENABLE_CLIP)] _Clip ("Clip", Float) = 0
        [Toggle(ISPARTICLE)] _IsParticle ("is particle", Float) = 0

        [HideInInspector] _EnableUi ("EnableUi", Float) = 0
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _CullMode ("__CullMode", Float) = 0.0
        [HideInInspector] _Cull ("__Cull", Float) = 0.0

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
    }

    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Pass {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite Off
            ZTest [_Ztest]
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ ENABLE_SECONDARYTEX
            #pragma multi_compile __ ENABLE_DISTORT
            #pragma multi_compile __ ENABLE_DISSOLVE
            #pragma multi_compile __ ENABLE_CLIP

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _SecondaryTex_ST, _DistortMap_ST, _MaskMap_ST, _DissolveMap_ST;
            float4 _MainTexUVAni, _UVAnination, _TintColor, _DissolveEdgeColor;
            float _DistortFactor, _ColorFactor, _DissolveFactor, _DissolveEdge;
            float4 _ClipRect, _ClipParam;
            float _IsParticle, _Mask, _EnableUi;
            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_SecondaryTex); SAMPLER(sampler_SecondaryTex);
            TEXTURE2D(_DistortMap); SAMPLER(sampler_DistortMap);
            TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
            TEXTURE2D(_DissolveMap); SAMPLER(sampler_DissolveMap);

            struct Attributes {
                float4 positionOS : POSITION;
                float4 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normal : NORMAL;
                float4 customData : TEXCOORD1;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2;
                float2 clipPos : TEXCOORD3;
                float4 color : COLOR;
                float4 customData : TEXCOORD4;
            };

            Varyings vert (Attributes IN) {
                Varyings OUT = (Varyings)0;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                float particleUVControl = lerp(1, IN.customData.x, _IsParticle);
                OUT.customData = lerp(float4(1,1,1,1), float4(IN.uv.zw, IN.customData.xy), _IsParticle);

                OUT.uv.xy = IN.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw * particleUVControl;
                OUT.uv.xy += frac(_MainTexUVAni.xy * _Time.y);

                #if defined(ENABLE_SECONDARYTEX)
                OUT.uv.zw = IN.uv.xy * _SecondaryTex_ST.xy + _SecondaryTex_ST.zw * particleUVControl;
                OUT.uv.zw += frac(_MainTexUVAni.zw * _Time.y);
                #endif

                #if defined(ENABLE_DISTORT)
                OUT.uv2.xy = TRANSFORM_TEX(IN.uv.xy, _DistortMap);
                OUT.uv2.xy += frac(_UVAnination.xy * _Time.y);
                #endif

                OUT.uv1.xy = TRANSFORM_TEX(IN.uv.xy, _MaskMap);

                #if defined(ENABLE_DISSOLVE)
                OUT.uv1.zw = TRANSFORM_TEX(IN.uv.xy, _DissolveMap);
                #endif

                #if defined(ENABLE_CLIP)
                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.clipPos = worldPos.xy;
                #endif

                OUT.color = IN.color;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target {
                half4 baseCol;

                #if !defined(ENABLE_DISTORT)
                    baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv.xy);
                #else
                    half distortVal = SAMPLE_TEXTURE2D(_DistortMap, sampler_DistortMap, IN.uv2.xy).r * 2 - 1;
                    half2 uvDistorted = IN.uv.xy + distortVal * _DistortFactor;
                    baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvDistorted);
                #endif

                #if defined(ENABLE_SECONDARYTEX)
                    half4 secCol = SAMPLE_TEXTURE2D(_SecondaryTex, sampler_SecondaryTex, IN.uv.zw);
                    baseCol *= secCol;
                #endif

                float uiAlpha = min(max(max(baseCol.r, baseCol.g), baseCol.b), baseCol.a);
                baseCol.a = lerp(baseCol.a, uiAlpha, _EnableUi);

                #if defined(ENABLE_DISSOLVE)
                    float dissolveTex = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, IN.uv1.zw).r;
                    float dissolveClip = step(0, dissolveTex - _DissolveFactor * IN.customData.x);
                    baseCol *= dissolveClip;
                #endif

                half3 rgb = baseCol.rgb * _TintColor.rgb * IN.color.rgb;
                half alpha = baseCol.a * _TintColor.a * IN.color.a;

                half4 result;
                result.rgb = rgb;
                result.a = alpha;

                half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, IN.uv1.xy).r;
                result.a = lerp(alpha, result.a * mask, _Mask);
                result.rgb *= _ColorFactor;

                #if defined(ENABLE_CLIP)
                    float2 inside = step(_ClipRect.xy, IN.clipPos) * step(IN.clipPos, _ClipRect.zw);
                    float inClip = inside.x * inside.y;
                    float dis = distance(_ClipParam.xy, IN.clipPos);
                    float radial = step(dis, _ClipParam.z);
                    float finalClip = lerp(radial, inClip, _ClipParam.w);
                    result *= finalClip;
                #endif

                return result;
            }
            ENDHLSL
        }
    }
}
