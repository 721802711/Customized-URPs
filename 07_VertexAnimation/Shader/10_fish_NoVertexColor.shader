Shader "B/10_fish_NoVertexColor"
{
    Properties
    {
        [Header(Body Movement)]
        _MainTex ("Texture", 2D) = "white" {}
        _SinMaxValue("Body Swing Amp", Float) = 0.5
        _Frequency("Body Swing Freq", Float) = 1.0 
        _Size("Body Swing Phase", Float) = 1.0

        [Header(Wing Animation)]
        // 【关键参数】控制身体多宽。超过这个宽度的部分会被视为翅膀。
        _BodyWidth("Body Width Threshold", Range(0, 2)) = 0.2
        _WingIntensity("Wing Flap Amp", Float) = 0.5
        _WingSpeed("Wing Flap Speed", Float) = 10.0
        _WingWaveLength("Wing Wave Length", Float) = 1.0

        [Space(20)]     
        [Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _SinMaxValue;
            float _Frequency;
            float _Size;
            
            // 翅膀参数
            float _BodyWidth; // 新增：身体宽度阈值
            float _WingIntensity;
            float _WingSpeed;
            float _WingWaveLength;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            // 不需要 color 了
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass
        {
            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;

                float4 offset = float4(0.0, 0.0, 0.0, 0.0);


                float bodyMask = abs(v.positionOS.y);
                bodyMask *= bodyMask; 
                offset.x = (_SinMaxValue * bodyMask) * sin(_Frequency * _Time.y + v.positionOS.y * _Size);


                // 计算该顶点距离中心(X=0)的距离
                float distFromCenter = abs(v.positionOS.x);

                float wingMask = smoothstep(_BodyWidth, _BodyWidth + 0.5, distFromCenter);

                float wingWave = sin(_WingSpeed * _Time.y + v.positionOS.x * _WingWaveLength);

                offset.z += wingWave * _WingIntensity * wingMask;

                // =======================================================

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz + offset.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}