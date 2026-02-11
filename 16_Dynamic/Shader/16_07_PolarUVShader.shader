Shader "B/PolarUVShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _ColorTex ("Color Texture", 2D) = "white" {}

        _Center  ("Center.xy & Tiling.zw", Vector) = (0.5, 0.5, 1, 1)
        [KeywordEnum(U_As_Angle, V_As_Angle)] _PolarMode ("Polar Mode", Float) = 0

        _AngleScale ("Angle Scale", Float) = 1.0
        _RadiusScale ("Radius Scale", Float) = 1.0

        _UVSpeed ("UV Scroll Speed (X = U, Y = V)", Vector) = (0, 0, 0, 0)

        _Color ("Tint Color", Color) = (1,1,1,1)
        _ColorIntensity ("Color Intensity", Float) = 1.0
        _PowValue ("Color Pow", Float) = 1.0

        _FlashSpeed ("Flash Speed", Float) = 2.0
        _FlashIntensity ("Flash Intensity", Float) = 1.0

        // ✅ 新增：闪动最小/最大值
        _FlashMin ("Flash Min", Float) = 0.2
        _FlashMax ("Flash Max", Float) = 1.0
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

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Center;
            float _AngleScale;
            float _RadiusScale;
            float4 _UVSpeed;
            float4 _Color;
            float _ColorIntensity;
            float _PowValue;
            float _FlashSpeed;
            float _FlashIntensity;
            float _FlashMin;
            float _FlashMax;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);

        ENDHLSL

        Pass
        {


            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off



            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature_local _POLARMODE_U_AS_ANGLE _POLARMODE_V_AS_ANGLE

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord   : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 delta = i.uv - _Center.xy;
                float radius = length(delta) * _RadiusScale;

                float angle = atan2(delta.y, delta.x);
                angle = (angle / (2.0 * 3.14159265) + 0.5) * _AngleScale;

                float2 polarUV;

                #if defined(_POLARMODE_U_AS_ANGLE)
                    polarUV = float2(angle, radius);
                #elif defined(_POLARMODE_V_AS_ANGLE)
                    polarUV = float2(radius, angle);
                #else
                    polarUV = float2(angle, radius);
                #endif

                polarUV.x *= _Center.z;
                polarUV.y *= _Center.w;
                polarUV += _UVSpeed.xy * _Time.y;

                float4 mainCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, polarUV);
                float4 colorCol = SAMPLE_TEXTURE2D(_ColorTex, sampler_ColorTex, i.uv);
                float4 finalColor = mainCol * colorCol;

                finalColor *= _Color;
                finalColor *= _ColorIntensity;
                finalColor.rgb = pow(finalColor.rgb, _PowValue);

                // ✅ 新闪动逻辑：从 _FlashMin ~ _FlashMax
                float raw = sin(_Time.y * _FlashSpeed) * 0.5 + 0.5;
                float flash = lerp(_FlashMin, _FlashMax, raw) * _FlashIntensity;
                finalColor.rgb *= flash;


                float alpha = saturate(finalColor.a);   // 用现有结果，不要覆盖
                finalColor.rgb *= alpha;               // 预乘避免叠加黑色
                return float4(finalColor.rgb, alpha);

            }

            ENDHLSL
        }
    }
}
