Shader "Custom/CloudFogURP"
{
    Properties
    {
        _CloudTex("Cloud Texture", 2D) = "white" {}
        _MaskTex("Mask Texture", 2D) = "white" {}
        _TillingFactor1("Tiling Factor 1", Float) = 1.0
        _TillingFactor2("Tiling Factor 2", Float) = 1.5
        _CloudSpeed("Cloud Speed (xy, zw)", Vector) = (0.1, 0.1, -0.1, -0.1)
        _ShadeOffset("Shade Offset Fix (x, y, scale)", Vector) = (0.5, 0.5, 1.0, 0.0)
        _MaskRvalues("Mask R (min, max, pow)", Vector) = (0.2, 0.8, 1.0, 0.0)

        _DissolveTex("Dissolve Texture", 2D) = "white" {}
        _DissolveStrength("Dissolve Strength",  Range(1, 10)) = 0.0
        _FlickSpeed("Flicker Speed", Float) = 1.0
        _FlickIntensity("Flicker Intensity", Float) = 0.5
        _DissolveMaskR("Mask R for Dissolve", Range(-10, 10)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"  "Queue"="Transparent"}
        LOD 200

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }


            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            TEXTURE2D(_CloudTex);
            SAMPLER(sampler_CloudTex);
            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);




            float _TillingFactor1;
            float _TillingFactor2;
            float4 _CloudSpeed;
            float3 _ShadeOffset;
            float3 _MaskRvalues;

            float _FlickSpeed;
            float _FlickIntensity;

            float _DissolveStrength;
            float _DissolveMaskR;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 BlendTwoCloud(float2 uv)
            {
                float4 c = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv * _TillingFactor1 + _Time.x * _CloudSpeed.xy);
                float3 c2 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv * _TillingFactor2 + _Time.x * _CloudSpeed.zw).rgb;
                c.rgb = (c.rgb + c2) / 2;
                return c;
            }

            float ClampAndPowValue(float val, float3 minMaxPow)
            {
                float mValue;
                mValue = saturate((val - minMaxPow.x) / (minMaxPow.y - minMaxPow.x));
                mValue = saturate(pow(mValue, minMaxPow.z));
                return mValue;
            }


            float DissolveMaskR(float3 mask, float2 dissolveUV, float DissolveAmount)
            {
                float dissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
                float maskR = lerp(mask.r * smoothstep(0, saturate(dissolve + DissolveAmount) + 0.01, DissolveAmount), mask.r, mask.b);

                return maskR;
            }



            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;
                float4 cloudColor = BlendTwoCloud(uv);
                float gray = dot(cloudColor.rgb, float3(0.333, 0.333, 0.333));
                float2 disOffset = float2(gray - _ShadeOffset.x, gray - _ShadeOffset.y) * _ShadeOffset.z * 0.01;
                float2 offsetUV = uv + disOffset;
                float4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, offsetUV);
                float unlock = ClampAndPowValue(mask.r, _MaskRvalues);


                float flickerSin = lerp(1, sin(_Time.y * _FlickSpeed), _FlickIntensity);
                float flicker = lerp(1.0, flickerSin, mask.g);


                float dissolveMask = DissolveMaskR(mask.rgb, offsetUV, _DissolveMaskR);


                cloudColor.rgb = cloudColor;
                cloudColor.a = dissolveMask;


                return cloudColor;
            }
            ENDHLSL
        }
    }
}
