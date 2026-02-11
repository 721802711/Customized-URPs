Shader "B/16_06_NeonLightWithBulbs"
{
    Properties
    {
        _ColorTex ("Color Texture", 2D) = "white" {}
        _MainTex ("Mask Texture", 2D) = "white" {}

        // 独立控制 R / G / B 显示色彩
        [HDR]_TintR ("Tint R", Color) = (1,1,1,1)
        [HDR]_TintG ("Tint G", Color) = (1,1,1,1)
        [HDR]_TintB ("Tint B", Color) = (1,1,1,1)
        [HDR]_TintA ("Tint A", Color) = (1,1,1,1)

        [KeywordEnum(TintColor, TextureColor)] _ColorMode ("Color Mode", Float) = 0

        // 两个独立闪烁速度
        _FlashSpeedBlue ("Flash Speed Blue", Float) = 2
        _FlashSpeedRG   ("Flash Speed R&G", Float) = 2

        // Texture Color 强度
        _ColorIntensity ("Color Intensity", Range(0, 10)) = 1

        // ✅ 新增 UV 移动属性
        _ColorUVSpeed ("ColorTex UV Speed (X=U, Y=V)", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _ColorTex_ST;
            float4 _TintR;
            float4 _TintG;
            float4 _TintB;
            float4 _TintA;
            float _ColorMode;
            float _FlashSpeedBlue;
            float _FlashSpeedRG;
            float _ColorIntensity;
            float4 _ColorUVSpeed; // UV动画速度
        CBUFFER_END

        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_ColorTex);   SAMPLER(sampler_ColorTex);

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord   : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv         : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _ColorTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 1) 采样 Mask
                float4 maskCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                // 2) 采样 ColorTex 并加 UV 动画
                float2 colorUV = i.uv.zw + _ColorUVSpeed.xy * _Time.y;
                float4 colorTex = SAMPLE_TEXTURE2D(_ColorTex, sampler_ColorTex, colorUV);

                // 闪烁计算
                float tBlue = _Time.y * _FlashSpeedBlue;
                float tRG   = _Time.y * _FlashSpeedRG;

                float blueBlink  = abs(sin(tBlue));
                float redBlink   = abs(sin(tRG));
                float greenBlink = abs(sin(tRG + 1.57079632679)); // pi/2 相位偏移

                // 通道遮罩
                float4 maskResult = float4(
                    maskCol.r * redBlink,
                    maskCol.g * greenBlink,
                    maskCol.b,
                    maskCol.a * blueBlink
                );

                // 合成 Mask 
                float maskAllAlpha = saturate(maskResult.r + maskResult.g + maskResult.b + maskResult.a);

                // 颜色来源分支
                int cm = (int)_ColorMode;
                float3 finalColor = float3(0,0,0);

                if (cm == 0)
                {
                    // TintColor 模式
                    float3 colorR = _TintR.rgb * maskResult.r;
                    float3 colorG = _TintG.rgb * maskResult.g;
                    float3 colorB = _TintB.rgb * maskResult.b;
                    float3 colorA = _TintA.rgb * maskResult.a;
                    finalColor = colorR + colorG + colorB + colorA;
                }
                else
                {
                    // TextureColor 模式
                    finalColor.r = colorTex.r;
                    finalColor.g = colorTex.g;
                    finalColor.b = colorTex.b;
                }

                // 乘以强度
                finalColor *= _ColorIntensity;

                // 输出半透明
                return half4(finalColor, maskAllAlpha);
            }

            ENDHLSL
        }
    }
}
