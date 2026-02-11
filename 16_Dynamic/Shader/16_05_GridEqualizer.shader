Shader "B/16_05_GridEqualizer"
{
    Properties
    {
        [HDR]_ColorA ("Color A", Color) = (1,0.2,0.8,1)
        [HDR]_ColorB ("Color B", Color) = (1,0.8,0.2,1)
        _Rows ("Rows", Float) = 6
        _Cols ("Cols", Float) = 10
        _Radius ("Rect Radius", Float) = 0.12
        _Spacing ("Spacing", Float) = 0.06
        _PosterizeSteps ("Posterize Steps", Range(1,16)) = 6
        _NoiseScale ("Noise Scale", Float) = 6.0
        _NoiseContrast ("Noise Contrast", Float) = 1.8
        _Speed ("Speed", Float) = 1.0
        _Intensity ("Intensity", Float) = 1.0
        _Threshold ("Step Threshold", Range(0,1)) = 0.5
        _UsePosterize ("Use Posterize (0/1)", Float) = 1
        _UseNoise ("Use Noise (0/1)", Float) = 1
        _MainTex("MainTex (optional)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Name "FORWARD_UNLIT"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Properties (copied to CBUFFER below)
            CBUFFER_START(UnityPerMaterial)
                float4 _ColorA;
                float4 _ColorB;
                float _Rows;
                float _Cols;
                float _Radius;
                float _Spacing;
                float _PosterizeSteps;
                float _NoiseScale;
                float _NoiseContrast;
                float _Speed;
                float _Intensity;
                float _Threshold;
                float _UsePosterize;
                float _UseNoise;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

            // ---------- helper functions ----------
            // 2D hash / noise (cheap)
            static float hash21(float2 p)
            {
                // from IQ's hash
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            static float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                // four corners
                float a = hash21(i + float2(0.0,0.0));
                float b = hash21(i + float2(1.0,0.0));
                float c = hash21(i + float2(0.0,1.0));
                float d = hash21(i + float2(1.0,1.0));
                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            // Rounded rectangle SDF (simple) in cell space [-0.5..0.5]
            static float roundedRectMask(float2 p, float2 size, float radius)
            {
                // p centered at 0
                float2 d = abs(p) - size + radius;
                d = max(d, 0.0);
                float outside = length(d) - radius;
                // inside -> negative, outside positive. return smoothstep mask [0..1]
                float m = 1.0 - saturate(outside * 10.0); // sharpness
                return m;
            }

            // posterize: quantize value to N steps
            static float posterize(float v, float steps)
            {
                if (steps <= 1.0) return v;
                float s = floor(v * steps + 0.0001) / max(1.0, steps - 1.0);
                return saturate(s);
            }

            // ---------- fragment ----------
            float4 Frag(Varyings i) : SV_Target
            {
                // uv centered on 0..1
                float2 uv = i.uv;

                // Keep aspect correction simple: treat uv as 0..1 space
                // Tile grid according to rows/cols
                float cols = max(1.0, _Cols);
                float rows = max(1.0, _Rows);

                // Flip Y if you like (here we keep standard)
                // Map uv to grid cell coordinates
                float2 gridUV = uv * float2(cols, rows);
                float2 cell = floor(gridUV);
                float2 fracUV = frac(gridUV); // 0..1 inside cell

                // create cell-local coordinates centered at 0
                float2 local = (fracUV - 0.5) * float2(1.0 - _Spacing, 1.0 - _Spacing);

                // size of inner rect (half-extent)
                // we want rectangles that occupy most of the cell width/height minus spacing
                float2 rectHalf = float2(0.5 * (1.0 - _Spacing), 0.5 * (1.0 - _Spacing));

                // Rounded rectangle mask
                float mask = roundedRectMask(local, rectHalf, _Radius);

                // Compute a per-cell "value" driven by noise and time to simulate animation/step
                // index-based offset so each cell differs
                float2 cellId = cell;
                // build a pseudo-random seed using cell coords
                float seed = hash21(cellId * 37.0 + 17.0);

                // time-driven animation
                float t = _Time.y * _Speed;

                // base noise (coarse)
                float n = 0.0;
                if (_UseNoise > 0.5)
                {
                    float2 npos = cellId / float2(cols, rows) * _NoiseScale + float2(t * 0.15, t * 0.23);
                    // combine a few octaves
                    n = noise(npos) * 0.6 + noise(npos * 1.9) * 0.3 + hash21(cellId + floor(t * 0.5)) * 0.1;
                    n = pow(n, _NoiseContrast);
                }
                else
                {
                    // fallback: constant determined by row for a bar-like effect
                    n = (rows - cellId.y) / rows;
                }

                // Simulate equalizer bars: create a row-based value, so lower rows light up first
                // 'barHeight' per column can be driven by noise + seed + time
                // We'll create a "value" in [0..1] that indicates how full the vertical bar is at this column
                // Use column-based seed so each column animates differently
                // combine column noise + smoothing by row
                float colSeed = hash21(float2(cellId.x, 999.0));
                float barValue = saturate( n * 1.2 + 0.2 * sin(t * 1.5 + colSeed * 6.2831) );

                // compute the normalized row position inside grid (0 bottom -> 1 top)
                float rowNorm = (cellId.y + 0.5) / rows;

                // compare rowNorm to barValue to decide if this cell's row is lit
                float stepMask = step(_Threshold, barValue - (1.0 - rowNorm));

                // alternative: smoothstep for anti-aliasing
                float smoothCut = smoothstep(0.0, 0.06, barValue - (1.0 - rowNorm));

                // Combine with mask (rounded rectangle)
                float finalAlpha = mask * smoothCut * _Intensity;

                // Posterize if requested (on the final value or color)
                float displayValue = finalAlpha;
                if (_UsePosterize > 0.5)
                {
                    displayValue = posterize(displayValue, max(1.0, _PosterizeSteps));
                }

                // color blend between A and B according to a global gradient or fraction of uv.y
                float mixT = uv.y; // or use other mapping
                float4 col = lerp(_ColorA, _ColorB, mixT);

                // modulate color by displayValue
                float4 outCol = col * displayValue;

                // optionally multiply by main texture (if provided)
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                // we allow mainTex to tint; multiply or blend depending on your intention:
                outCol.rgb *= mainTex.rgb;
                outCol.a = saturate(displayValue);

                return outCol;
            }

            ENDHLSL
        } // pass
    } // subshader

    FallBack Off
}
