Shader "B/11_10_Dissolve_Directional_Optimized"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.01, 0.2)) = 0.1 // 最小值设为0.01防止除以0

        [Space(20)]
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _RampTexGlowIntensity ("Ramp Glow Intensity", Range(0, 5)) = 1
        // 1. 增加枚举类型，支持从 UI 下拉切换
        [Enum(UP, 0, DOWN, 1, LEFT, 2, RIGHT, 3)] _DissolveDir("Dissolve Direction", Float) = 0
        
        _MinBorder ("Min Border (Local)", Float) = -0.5 
        _MaxBorder ("Max Border (Local)", Float) = 0.5  
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Cull Off
        LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _NoiseTex_ST;
            half _Threshold;
            float _EdgeLength;
            float _DissolveDir; // 枚举在 Shader 中以 float 处理
            float _MinBorder;
            float _MaxBorder;
            half _DistanceEffect;
            half _RampTexGlowIntensity;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord   : TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float4 uv         : TEXCOORD0;
            float3 localPos   : TEXCOORD1; // 传递本地坐标进行位置判断
        };

        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
        TEXTURE2D(_RampTex);    SAMPLER(sampler_RampTex);
        ENDHLSL

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                o.localPos = v.positionOS.xyz; // 记录本地坐标 [cite: 11]
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 优化计算：预计算范围倒数可以提升性能
                float range = _MaxBorder - _MinBorder;
                float invRange = 1.0 / max(range, 0.0001);
                
                // 2. 根据枚举切换溶解逻辑
                float currentPos = 0;
                float border = _MinBorder;

                // 使用枚举判断方向
                // 0: UP (Y正方向), 1: DOWN (Y负方向), 2: LEFT (X负方向), 3: RIGHT (X正方向)
                if (_DissolveDir == 0) { // UP
                    currentPos = i.localPos.y;
                    border = _MaxBorder;
                }
                else if (_DissolveDir == 1) { // DOWN
                    currentPos = i.localPos.y;
                    border = _MinBorder;
                }
                else if (_DissolveDir == 2) { // LEFT
                    currentPos = i.localPos.x;
                    border = _MinBorder;
                }
                else { // RIGHT
                    currentPos = i.localPos.x;
                    border = _MaxBorder;
                }

                // 计算到边界的归一化距离 
                float dist = abs(currentPos - border);
                float normalizedDistance = saturate(dist * invRange);

                // 结合噪声与距离效果 [cite: 14]
                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r;
                float cutout = noise * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                
                // 裁剪像素
                clip(cutout - _Threshold);

                // 计算边缘渐变 (Degree) 
                float degree = saturate((cutout - _Threshold) / _EdgeLength);
                
                // 采样渐变贴图，建议坐标使用 float2(degree, 0.5) 确保采样稳定
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, 0.5)) * _RampTexGlowIntensity;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                
                // 混合边缘色与主贴图
                half3 finalRGB = lerp(edgeColor.rgb, col.rgb, degree);

                return half4(finalRGB, 1.0);
            }
            ENDHLSL
        }
    }
}