Shader "Effect/11_15_MaskTransition"
{
    Properties
    {
        _MainTex ("Main Texture (Screen)", 2D) = "white" {}
        [NoScaleOffset] _MaskTex ("Mask Texture", 2D) = "white" {}
        _Progress ("Transition Progress", Range(0, 1)) = 0.0
        _MaxScale ("Max Mask Scale", Float) = 15.0
        [Toggle(USE_DEFAULT_CIRCLE)] _UseDefaultCircle ("Use Default Circle Mask", Float) = 1.0
        _TransitionBgColor ("Transition Background Color", Color) = (1,1,1,1)

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10

    }
    SubShader
    {
        Tags{ "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend[_SrcBlend][_DstBlend]
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Progress;
            float _MaxScale;
            float4 _TransitionBgColor;
            float _UseDefaultCircle;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float4 vertexColor : COLOR;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 vertexColor : COLOR;
        };

        TEXTURE2D(_MainTex);  SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);  SAMPLER(sampler_MaskTex);

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_DEFAULT_CIRCLE

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.vertexColor = v.vertexColor;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 0~0.1 阶段：透明度从 0 变 1，模糊程度从最大变 0
                float globalAlpha = saturate(_Progress * 10.0);
                float blurAmount = (1.0 - globalAlpha) * 0.05; // 最大0.05的模糊偏移
                
                half4 mainCol = half4(0,0,0,0);
                if (blurAmount > 0.001)
                {
                    // 四次采样模糊
                    mainCol += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(blurAmount, blurAmount));
                    mainCol += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-blurAmount, blurAmount));
                    mainCol += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(blurAmount, -blurAmount));
                    mainCol += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-blurAmount, -blurAmount));
                    mainCol *= 0.25;
                }
                else
                {
                    mainCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                }
                mainCol *= i.vertexColor;

                // Scale controls the size of the mask.
                // Progress goes 0 -> 1. 
                // Progress = 0: Mask covers full screen (scale = _MaxScale to cover corners)
                // Progress = 1: Mask shrinks to tiny dot / 0 (scale = ~0)
                float currentScale = lerp(_MaxScale, 0.0001, _Progress);
                
                float2 center = float2(0.5, 0.5);
                
                // offset UV to center, apply scale, and move back
                float2 maskUV = (i.uv - center) / currentScale + center;

                float maskAlpha = 0.0;

                #ifdef USE_DEFAULT_CIRCLE
                    // Math-based circle: 1.0 inside the circle (radius 0.5), 0.0 outside
                    float dist = distance(maskUV, center);
                    // Add slight soft edge for anti-aliasing
                    maskAlpha = 1.0 - smoothstep(0.49, 0.5, dist);
                #else
                    // Sample from custom mask texture (using Red channel)
                    float maskVal = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskUV).r;
                    
                    // Clamp to 0 if UV is outside [0, 1] to prevent repeat artifacts
                    float2 inBounds2 = step(0.0, maskUV) * step(maskUV, 1.0);
                    float inBounds = inBounds2.x * inBounds2.y;
                    
                    maskAlpha = maskVal * inBounds;
                #endif

                // 修改中心为透明，边缘为不透明颜色
                // maskAlpha == 1.0 (遮罩内部/中心): 透明 (Alpha = 0)
                // maskAlpha == 0.0 (遮罩外部/边缘): 边缘颜色 (Alpha = 1)
                
                half4 edgeColor = mainCol * _TransitionBgColor;
                
                half4 finalColor = edgeColor;
                // 反转 Alpha，使内部完全透明，外部实体
                // 另外再乘以 globalAlpha 确保 0 变 0.1 阶段整体有一个透明淡出的过渡
                finalColor.a = edgeColor.a * (1.0 - maskAlpha) * globalAlpha;
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}
