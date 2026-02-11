Shader "B/16_02_MonitorMusic"
{
    Properties
    {
        _ForegroundColor ("Foreground Color", Color) = (1,1,1,1)
        _BackgroundColor ("Background Color", Color) = (0,0,0,1)


        // 渐变色
        [HDR]_TopColor ("Top Gradient Color", Color) = (1,0,0,1)
        [HDR]_BottomColor ("Bottom Gradient Color", Color) = (0,0,1,1)



        _Columns ("Columns (tiles X)", Float) = 6
        _Rows ("Rows (tiles Y)", Float) = 10

        _Offset ("UV Offset (X,Y)", Vector) = (0,0,0,0)
        _TileScale ("Tile Scale (X,Y)", Vector) = (1,1,0,0)

        _CellWidth ("Cell Width", Range(0.01,1.0)) = 0.8
        _CellHeight ("Cell Height", Range(0.01,1.0)) = 0.8
        _CornerRadius ("Corner Radius", Range(0.0,0.5)) = 0.08

        _GlobalMaskHeight ("Global Mask Height", Range(0,1)) = 0.5
        _MaskFeather ("Mask Feather", Range(0.0,0.1)) = 0.002

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseStrength ("Noise Strength", Range(0,1)) = 1.0
        _NoiseSteps ("Noise Posterize Steps", Range(2,10)) = 4
        _NoiseScale ("Noise UV Base Scale", Float) = 1.0

        // X,Y控制移动；Z控制U平铺次数；W控制V平铺次数
        _NoiseSpeed ("Noise UV (MoveX, MoveY, TileU, TileV)", Vector) = (0.1, 0.1, 1.0, 1.0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _ForegroundColor;
                float4 _BackgroundColor;
                float4 _TopColor;
                float4 _BottomColor;
                float _Columns;
                float _Rows;
                float4 _Offset;
                float4 _TileScale;
                float _CellWidth;
                float _CellHeight;
                float _CornerRadius;
                float _GlobalMaskHeight;
                float _MaskFeather;
                float _NoiseStrength;
                float _NoiseSteps;
                float _NoiseScale;
                float4 _NoiseSpeed;
            CBUFFER_END

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv = v.uv;
                return o;
            }

            static float sdRoundedRect(float2 uvLocal, float2 size, float r)
            {
                float2 p = uvLocal - 0.5;
                float2 half = size * 0.5;
                float2 q = abs(p) - half;
                float2 qmax = max(q, 0.0);
                float outsideDist = length(qmax);
                float inside = min(max(q.x, q.y), 0.0);
                return outsideDist + inside - r;
            }

            float posterize(float v, float steps)
            {
                return floor(v * steps) / (steps - 1.0);
            }

            float4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;

                // ---- 网格UV ----
                float2 tiling = float2(_Columns, _Rows) * _TileScale.xy;
                float2 tiledUV = uv * tiling + _Offset.xy;
                float2 cellUV = frac(tiledUV);

                // ---- 圆角矩形 ----
                float sd = sdRoundedRect(cellUV, float2(_CellWidth, _CellHeight), _CornerRadius);
                float aa = max(fwidth(sd), 1e-6);
                float rectMask = smoothstep(0.0, -aa, sd);

                // ---- 动态噪声 ----
                // 每个 tile 使用对应的 noise cell
                float2 noiseBaseUV = float2(floor(tiledUV.x) / _Columns, floor(tiledUV.y) / _Rows);

                // XY 控制移动；ZW 控制平铺次数
                float2 move = _Time.y * _NoiseSpeed.xy;
                float2 tileRepeat = max(_NoiseSpeed.zw, 0.0001); // 防止除0

                // 按次数平铺噪声图
                float2 noiseUV = noiseBaseUV * tileRepeat * _NoiseScale + move;

                // 采样 + 阶梯化
                float noiseSample = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
                noiseSample = posterize(noiseSample, _NoiseSteps);

                // ---- 动态 Mask ----
                float localHeight = _GlobalMaskHeight + (noiseSample - 0.5) * _NoiseStrength;

                float stepMask = 1.0 - smoothstep(localHeight - _MaskFeather, localHeight + _MaskFeather, uv.y);
                float finalMask = rectMask * stepMask;

                float4 result = lerp(_BackgroundColor, _ForegroundColor, saturate(finalMask));

                // ---- 颜色渐变 ----
                float4 gradientColor = lerp(_BottomColor, _TopColor, uv.y); 
                result.rgb *= gradientColor;

                return result;
            }
            ENDHLSL
        }
    }
}
