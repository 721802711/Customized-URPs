Shader "B/06_21_Matrices"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Half, Shaped, Slanted, Lines, Ring)] _Dir ("Anim Direction", float) = 0

        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _cull ("cull Mode", Float) = 0 
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}

        LOD 100


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

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


            #pragma multi_compile _ _DIR_SHAPED _DIR_SLANTED _DIR_LINES _DIR_RING

            float Stroke(float x, float s, float w)
            {
                float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);

                return clamp(d, 0.0, 1.0);
            }

            float CircleSDF(float2 st)
            {
                return length(st - 0.5) * 2.0;
            }

            float Flip(float v, float pct)
            {
                return lerp(v, 1.0-v, pct);
            }


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = float4(0.0,0.0,0.0,0.0);
                float2 uv = i.uv;

                float3 pct = step(0.5, uv.x);
                #if _DIR_SHAPED 
                    pct = step(0.5 + cos(uv.y * PI) * 0.25, uv.x);
                #elif _DIR_SLANTED
                    pct = step(0.5, (uv.x + uv.y) * 0.5);
                #elif _DIR_LINES
                    pct = Stroke(uv.x, 0.5, 0.15);
                #elif _DIR_RING
                    pct = Stroke(CircleSDF(uv), 0.5, 0.05);
                #endif

                col.rgb += pct;

                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}