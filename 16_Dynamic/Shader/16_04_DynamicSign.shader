Shader "B/16_04_DynamicSign"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        [HDR]_BaseColor ("Base Color", Color) = (1,1,1,1)
        [HDR]_EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _TilingCount ("Tiling Count X", Float) = 5
        _Speed ("Light Flow Speed", Float) = 1.0
        _GlowWidth ("Glow Width", Range(0,1)) = 0.3
        _Contrast ("Glow Contrast", Float) = 4.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One One
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // ===== Properties =====
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float4 _BaseColor;
            float4 _EmissionColor;
            float _TilingCount;
            float _Speed;
            float _GlowWidth;
            float _Contrast;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // 重复贴图
                float2 uv = i.uv;
                uv.x *= _TilingCount;
                uv.x = frac(uv.x); // 让X方向重复

                // 基础贴图颜色
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _BaseColor;

                // 动态流动光带
                float t = frac(_Time.y * _Speed);
                float glowPos = uv.x;
                float glow = saturate(1.0 - abs(glowPos - t) / _GlowWidth);
                glow = pow(glow, _Contrast); // 控制亮度过渡

                // 混合基础色与发光色
                float3 color = baseCol.rgb * glow * _EmissionColor.rgb + baseCol.rgb * (1.0 - glow);

                return float4(color.xyz, baseCol.a);
            }
            ENDHLSL
        }
    }
}
