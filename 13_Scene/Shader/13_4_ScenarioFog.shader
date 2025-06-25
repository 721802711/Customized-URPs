Shader "B/13_4_ScenarioFog"
{
    Properties
    {
        _MainTex ("Cloud Noise Tex", 2D) = "white" {}
        _MaskTex ("Mask Tex", 2D) = "white" {}
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}

        _TillingFactor ("Tiling Factor", Float) = 1.0
        _CloudSpeed ("Cloud Speed (xy, zw)", Vector) = (0.1, 0.1, -0.05, -0.05)

        _shadeOffset ("Shade UV Offset (x, y, scale)", Vector) = (0.1, 0.1, 1.0)
        _MaskRvalues ("MaskR Clamp (x=min,y=max,z=pow)", Vector) = (0.2, 0.8, 1.0)

        _FlickSpeed ("Flicker Speed", Float) = 1.0
        _FlickIntensity ("Flicker Intensity", Float) = 0.5
        _FlickLevel ("Flicker Level", Range(1, 10)) = 0.5

        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _TillingFactor;
        float4 _CloudSpeed;
        float _EdgeOffset;
        float4 _UVOffsetFix;
        float _SelectionFlashStrength;
        float3 _ClampEdge;
        float3 _MaskRvalues;
        float3 _shadeOffset;
        float _FlickSpeed;
        float _FlickIntensity;
        float _FlickLevel;
        float _DissolveAmount;
        CBUFFER_END

        TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);      SAMPLER(sampler_MaskTex);
        TEXTURE2D(_DissolveTex);  SAMPLER(sampler_DissolveTex);

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

        float ClampAndPowValue(float val, float3 minMaxPow)
        {
            float mValue = saturate((val - minMaxPow.x) / (minMaxPow.y - minMaxPow.x));
            return saturate(pow(mValue, minMaxPow.z));
        }

        float4 BlendTwoCloud(float2 uv)
        {
            float4 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv * _TillingFactor + _Time.x * _CloudSpeed.xy);
            float3 c2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + _Time.x * _CloudSpeed.zw);
            c1.rgb = (c1.rgb + c2) * 0.5;
            return c1;
        }

        float DissolveMaskG(float3 mask, float2 dissolveUV, float DissolveAmount)
        {
            float dissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
            float dissolveMask = smoothstep(DissolveAmount - 0.1, DissolveAmount + 0.1, dissolve);
            return mask.g * (1.0 - dissolveMask);
        }

        ENDHLSL

        Pass
        {
            Name "FogPass"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                // 云纹理混合
                half4 cloudColor = BlendTwoCloud(uv);

                // 灰度值控制 UV 偏移
                float gray = dot(cloudColor.rgb, float3(0.3333, 0.3333, 0.3333));
                float2 disOffset = (gray - _shadeOffset.xy) * _shadeOffset.z * 0.01;

                // 采样 Mask
                float4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uv + disOffset);

                // mask.r 控制显示区域
                float maskG = ClampAndPowValue(mask.r, _MaskRvalues.xyz);

                // mask.g 控制高亮 + 溶解
                float dissolvedG = DissolveMaskG(mask.rgb, uv, _DissolveAmount);

                // 高亮闪烁效果
                float flicker = lerp(1.0, sin(_Time.y * _FlickSpeed), _FlickIntensity);
                cloudColor.rgb += cloudColor.rgb * flicker * dissolvedG * _FlickLevel;

                // 最终透明度（只由 r 通道控制）
                float alpha = cloudColor.a * mask.r;

                return float4(cloudColor.rgb, alpha);
            }
            ENDHLSL
        }
    }
}
