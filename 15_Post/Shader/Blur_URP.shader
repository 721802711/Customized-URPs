Shader "B/RadialBlur"
{
    Properties
    {
        _BlitTexture ("Source Texture", 2D) = "white" {}
        _BlurRadius ("Blur Radius", Float) = 2.0
    }

    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent"      // ✅ 渲染层级设为 3000
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100
        ZWrite Off
        Cull Off
        Blend Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BlitTexture_ST;
        float _BlurRadius;
        CBUFFER_END

        TEXTURE2D(_BlitTexture);
        SAMPLER(sampler_BlitTexture);

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        v2f vert(appdata v)
        {
            v2f o;
            VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
            o.positionCS = posInputs.positionCS;
            o.uv = TRANSFORM_TEX(v.texcoord, _BlitTexture);
            return o;
        }

        half4 frag(v2f i) : SV_Target
        {
            static const half weights[9] = {
                0.05, 0.09, 0.12, 0.15, 0.18,
                0.15, 0.12, 0.09, 0.05
            };

            float2 uv = i.uv;
            half4 col = 0;
            float total = 0;

            for (int j = 0; j < 9; j++)
            {
                float angle = (6.2831853 / 9) * j;
                float2 dir = float2(cos(angle), sin(angle));
                float2 offsetUV = uv + dir * (_BlurRadius * 0.001);
                half4 sampleCol = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, offsetUV);
                col += sampleCol * weights[j];
                total += weights[j];
            }

            return col / total;
        }
        ENDHLSL

        Pass
        {
            Name "RadialBlurPass"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
