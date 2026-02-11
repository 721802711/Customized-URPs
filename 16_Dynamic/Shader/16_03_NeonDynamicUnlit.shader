Shader "B/16_03_NeonDynamicUnlit"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _EmissionStrength ("Emission Strength", Float) = 2.0
        _Speed ("Scroll Speed", Float) = 1.0
        [KeywordEnum(MeshUV, WorldUV, ScreenUV)] _UVMode ("UV Mode", Float) = 0
        _Direction ("Direction (0=X,1=Y)", Float) = 0.0
        _WorldScale ("World UV Scale", Float) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "NeonTexMultiUV"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile _UVMODE_MESHUV _UVMODE_WORLDUV _UVMODE_SCREENUV

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // --- 属性定义 ---
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float4 _MainColor;
            float _EmissionStrength;
            float _Speed;
            float _Direction;
            float _WorldScale;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.screenPos = ComputeScreenPos(OUT.positionCS);
                return OUT;
            }

            float4 Frag(Varyings IN) : SV_Target
            {
                float2 uv = 0;

                #if defined(_UVMODE_MESHUV)
                    // 模型UV
                    uv = IN.uv;
                #elif defined(_UVMODE_WORLDUV)
                    // 世界空间UV
                    uv = IN.worldPos.xz * _WorldScale;
                #elif defined(_UVMODE_SCREENUV)
                    // 屏幕UV
                    uv = IN.screenPos.xy / IN.screenPos.w;
                #endif

                // 滚动
                float t = _Time.y * _Speed;
                if (_Direction < 0.5)
                    uv.x += t;
                else
                    uv.y += t;

                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float3 finalColor = texColor.rgb * _MainColor.rgb * _EmissionStrength;

                return float4(finalColor, texColor.a * _MainColor.a);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
