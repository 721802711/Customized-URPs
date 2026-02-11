Shader "B/00_Vertex"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [KeywordEnum(None, Translate, Scale, Rotate, ZWave, XYWave)] _Dir ("Anim Direction", float) = 0

        _MoveSpeed ("Move Speed" , Float) = 1
        _MoveRange ("Move Range" , Float) = 1
        _RotateRange("Rotate Range", Range(0, 180)) = 0

        _WaveAmpX ("X Wave Amplitude", Float) = 0.0
        _WaveAmpY ("Y Wave Amplitude", Float) = 0.0

        [HDR]_BaseColor("Base Color", Color) = (1,1,1,1)

        // GPU blend control shown in inspector (choose source/dest blend factors)
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10

        // Shader-side color blend mode and strength:
        // _ColorBlendMode: 0 = Linear (lerp), 1 = Multiply
        _ColorBlendMode("Color Blend Mode (0=Lerp,1=Multiply)", Float) = 0
        _BlendFactor("Color Blend Strength", Range(0,1)) = 1.0

        [Space(20)]
        [Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _MoveSpeed;
        float _MoveRange;
        float _RotateRange;
        float _WaveAmpX;
        float _WaveAmpY;
        float4 _BaseColor;
        float _ColorBlendMode;
        float _BlendFactor;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float4 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 normalWS : TEXCOORD1;
        };

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass
        {
            // <-- GPU blend factors are provided by material properties (enum ints)
            Blend [_SrcBlend] [_DstBlend]
            Cull [_cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define TWO_PI 6.283185

            #pragma multi_compile _ _DIR_TRANSLATE _DIR_SCALE _DIR_ROTATE _DIR_ZWAVE _DIR_XYWAVE

            // 平移函数
            float3 Translation(float3 positionOS)
            {
                positionOS.y += _MoveRange * sin(frac(_Time.z * _MoveSpeed) * TWO_PI);
                return positionOS;
            }

            // 缩放函数
            float3 Scale(float3 positionOS)
            {
                positionOS *= 1.0 + sin(frac(_Time.y * _MoveSpeed) * TWO_PI) * _MoveRange;
                return positionOS;
            }

            // 旋转函数
            float3 Rotation(float3 positionOS, float Range, float Speed)
            {
                float angleY = Range * sin(frac(_Time.y * Speed) * TWO_PI);
                float radianY = radians(angleY);

                float sin_radianY, cos_radianY;
                sincos(radianY, sin_radianY, cos_radianY);

                float2x2 Rotate_Matrix_Y = float2x2(cos_radianY, sin_radianY, -sin_radianY, cos_radianY);
                positionOS.xz = mul(Rotate_Matrix_Y, float2(positionOS.x, positionOS.z));
                return positionOS;
            }

            // Z 轴波浪
            float3 ZWaveMotion(float3 positionOS)
            {
                float phase = positionOS.x + positionOS.y;
                positionOS.z += _MoveRange * sin(_Time.y * _MoveSpeed + phase);
                return positionOS;
            }

            // XY 波浪
            float3 XYWaveMotion(float3 positionOS)
            {
                float t = _Time.y * _MoveSpeed;
                float phase = positionOS.x + positionOS.y;

                positionOS.x += _WaveAmpX * sin(t + phase);
                positionOS.y += _WaveAmpY * cos(t + phase);
                positionOS.z += _MoveRange * sin(t + phase);

                return positionOS;
            }

            v2f vert (appdata v)
            {
                v2f o;
                float3 objectPos = v.positionOS.xyz;

                #if _DIR_TRANSLATE
                    objectPos = Translation(v.positionOS.xyz);
                #elif _DIR_SCALE
                    objectPos = Scale(v.positionOS.xyz);
                #elif _DIR_ROTATE
                    objectPos = Rotation(v.positionOS.xyz, _RotateRange, _MoveSpeed);
                #elif _DIR_ZWAVE
                    objectPos = ZWaveMotion(v.positionOS.xyz);
                #elif _DIR_XYWAVE
                    objectPos = XYWaveMotion(v.positionOS.xyz);
                #endif

                VertexPositionInputs PositionInputs = GetVertexPositionInputs(objectPos);
                o.positionCS = PositionInputs.positionCS;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // Sample texture
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // Base color (可含 alpha)
                float4 baseCol = _BaseColor;

                float4 outCol;

                // 使用运行时分支选择 shader 内的颜色叠加逻辑
                // 0 = Linear (lerp by BlendFactor * base.alpha)
                // 1 = Multiply (tex * baseCol) with BlendFactor controlling intensity of multiply
                if (_ColorBlendMode < 0.5)
                {
                    float t = saturate(_BlendFactor * baseCol.a);
                    outCol = lerp(tex, baseCol, t);
                }
                else
                {
                    // Multiply: allow partial strength via BlendFactor
                    float3 mult = tex.rgb * baseCol.rgb;
                    outCol.rgb = lerp(tex.rgb, mult, saturate(_BlendFactor));
                    // alpha combine: multiply alpha (then optionally scale by factor)
                    outCol.a = tex.a * baseCol.a * saturate(_BlendFactor) + tex.a * (1 - saturate(_BlendFactor));
                }

                return outCol;
            }
            ENDHLSL
        }
    }
}
