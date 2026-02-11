Shader "URP/CameraBlur"
{
    Properties
    {
        _BlurRadius("Blur Radius", Range(0, 1)) = 0.5
        _TintColor("Tint Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalPipeline" 
            "Queue"="Transparent" 
            "RenderType"="Transparent" 
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _BlurRadius;
        float4 _TintColor;
        CBUFFER_END

        TEXTURE2D(_CameraOpaqueTexture);
        SAMPLER(sampler_CameraOpaqueTexture);

        struct a2v
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float4 screenPos : TEXCOORD0;
        };

        float4 ComputeScreenPosURP(float4 posCS)
        {
            float4 o = posCS * 0.5f;
            o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
            o.zw = posCS.zw;
            return o;
        }

        ENDHLSL

        Pass
        {
            Name "CameraBlur"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInput.positionCS;
                o.screenPos = ComputeScreenPosURP(o.positionCS);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.screenPos.xy / i.screenPos.w;

                // 9向模糊采样
                float2 offsets[9] = {
                    float2(-1,-1), float2(0,-1), float2(1,-1),
                    float2(-1, 0), float2(0, 0), float2(1, 0),
                    float2(-1, 1), float2(0, 1), float2(1, 1)
                };

                half4 col = 0;
                for(int j = 0; j < 9; j++)
                {
                    float2 sampleUV = uv + offsets[j] * (_BlurRadius * 0.01);
                    col += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, sampleUV);
                }

                return (col / 9.0) * _TintColor;
            }

            ENDHLSL
        }
    }
}
