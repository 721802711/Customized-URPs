Shader "B/13_fish_3Axis"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Header(Wave Settings)]
        _SinMaxValue("Sin Max Value", Float) = 0.5
        _Frequency("Frequency", Float) = 1.0 
        _Size("Size", Float) = 1.0

        [Header(Axis Configuration)]
        // 红框 1：遮罩轴 (Mask Axis) - 决定哪里动哪里不动
        [Enum(X,0,Y,1,Z,2)] _MaskAxis("1. Mask Axis (Input)", Float) = 1 // 默认 Y
        
        // 红框 3：波浪轴 (Wave Axis) - 决定波浪沿哪个方向传导
        [Enum(X,0,Y,1,Z,2)] _WaveAxis("3. Wave Axis (Input)", Float) = 1 // 默认 Y

        // 红框 2：位移轴 (Displace Axis) - 决定摆动方向
        [Enum(X,0,Y,1,Z,2)] _DisplaceAxis("2. Displace Axis (Output)", Float) = 0 // 默认 X

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
            // 三个轴的变量
            float _MaskAxis;
            float _WaveAxis;
            float _DisplaceAxis;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
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

            // 辅助函数：读取指定轴的数值
            float GetAxisValue(float3 pos, float axisSelector)
            {
                if (axisSelector < 0.5) return pos.x;       // 0 = X
                else if (axisSelector < 1.5) return pos.y;  // 1 = Y
                else return pos.z;                          // 2 = Z
            }

            v2f vert (appdata v)
            {
                v2f o;

                float4 offset = float4(0.0, 0.0, 0.0, 0.0);

                // --- 1. 红框位置：获取遮罩轴数值 (Mask) ---
                // 对应原来的 abs(v.positionOS.y)
                float maskInput = GetAxisValue(v.positionOS.xyz, _MaskAxis);
                float swingMask = abs(maskInput);
                swingMask *= swingMask;

                // --- 2. 红框位置：获取波浪轴数值 (Wave) ---
                // 对应原来的 sin(... + v.positionOS.y * _Size)
                float waveInput = GetAxisValue(v.positionOS.xyz, _WaveAxis);

                // 计算波浪值
                float waveValue = (_SinMaxValue * swingMask) * sin(_Frequency * _Time.y + waveInput * _Size);
                
                // --- 3. 红框位置：应用到位移轴 (Output) ---
                // 对应原来的 offset.x = ...
                if (_DisplaceAxis < 0.5)      offset.x = waveValue; // 0 = X
                else if (_DisplaceAxis < 1.5) offset.y = waveValue; // 1 = Y
                else                          offset.z = waveValue; // 2 = Z

                // 最终位置计算 (模型空间 -> 裁剪空间)
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