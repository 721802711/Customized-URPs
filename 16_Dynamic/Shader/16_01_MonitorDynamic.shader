Shader "B/16_01_MonitorDynamic"
{
    Properties
    {
        [HDR]_BaseColor("BaseColor", Color) = (1,1,1,1)
        _MainTex("MainTex", 2D) = "White" {}

        _x_Sum("x", Float) = 3
        _y_Sum("y", Float) = 3 
        _ShowID("_ShowID", Float) = 0
        [Toggle(_AutoPlay)] _AutoPlay("Play", Float) = 0
        _Speed("_Speed", Float) = 1


        [Toggle(_RandomShow)] _RandomShow("Random Show", Float) = 0
        _ColorIntensity("Color Intensity", Range(0, 3)) = 1


        [Header(CRT Settings)]
        _ScanlineIntensity("Scanline Intensity", Range(0, 2)) = 1
        _ChromaticOffset("Chromatic Offset", Range(0, 3)) = 1.5
        _VignetteStrength("Vignette Strength", Range(0, 1)) = 0.4

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend [_SrcBlend] [_DstBlend]
        Cull Off
        ZWrite Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Speed;
        float _ShowID;
        float _x_Sum, _y_Sum;

        float _ScanlineIntensity;
        float _ChromaticOffset;
        float _VignetteStrength;


        float _ColorIntensity;



        CBUFFER_END

        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _AutoPlay
            #pragma shader_feature _RandomShow


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                #ifdef _AutoPlay
                    _ShowID += _Time.y * _Speed;
                #endif

                #ifdef _RandomShow
                    float totalCount = _x_Sum * _y_Sum;

                    // 用 Speed 控制随机切换频率
                    float t = floor(_Time.y * _Speed);   // 每隔 1/_Speed 秒更新
                    float rnd = frac(sin(t) * 43758.5453);

                    _ShowID = (int)floor(rnd * totalCount);
                #else
                    _ShowID = floor(fmod(_ShowID, _x_Sum * _y_Sum));
                #endif


                float indexY = floor(_ShowID / _x_Sum);
                float indexX = _ShowID - _x_Sum * indexY;

                float2 baseUV = float2(i.uv.x / _x_Sum, i.uv.y / _y_Sum);
                baseUV.x += indexX / _x_Sum;
                baseUV.y += (_y_Sum - 1 - indexY) / _y_Sum;

                // 1️⃣ Chromatic aberration (RGB 偏移)
                float2 uvR = baseUV + float2(_ChromaticOffset / 1000.0, 0);
                float2 uvB = baseUV - float2(_ChromaticOffset / 1000.0, 0);

                half r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvR).r;
                half g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, baseUV).g;
                half b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvB).b;

                half3 col = half3(r, g, b);

                // 2️⃣ Scanline（水平扫描线）
                float scan = sin(i.uv.y * _ScreenParams.y * 1.5);
                col *= 1.0 - _ScanlineIntensity * 0.3 * (0.5 + 0.5 * scan);

                // 3️⃣ Vignette（暗角）
                float2 v = i.uv - 0.5;
                float vignette = 1.0 - _VignetteStrength * dot(v, v) * 2.5;
                col *= saturate(vignette);

                col *= _ColorIntensity;
                return half4(col, _BaseColor.a) * _BaseColor;

            }
            ENDHLSL
        }
    }
}
