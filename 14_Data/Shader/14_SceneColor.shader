Shader "URP/GlassDistortion"
{
    Properties
    {
        _MainTex("Base Texture", 2D) = "white" {}
        _BumpMap("Bump Map", 2D) = "bump" {}
        _Magnitude("Distortion Magnitude", Range(0,1)) = 0.05
        _Color("Tint Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _BumpMap_ST;
        float4 _Color;
        float _Magnitude;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_BumpMap);
        SAMPLER(sampler_BumpMap);
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
            float2 uv : TEXCOORD0;
            float4 screenPos : TEXCOORD1;
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
            Name "GlassDistortion"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPosURP(o.positionCS);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // Base and bump map
                float2 uv = i.uv;
                float3 bump = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv).xyz;
                float2 distortion = (bump.xy * 2.0 - 1.0) * _Magnitude;

                // Screen UV after distortion
                float2 screenUV = i.screenPos.xy / i.screenPos.w + distortion;

                // Sample screen
                half4 screenCol = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                return screenCol * baseCol * _Color;
            }

            ENDHLSL
        }
    }
}
