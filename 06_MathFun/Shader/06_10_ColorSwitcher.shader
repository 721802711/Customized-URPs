Shader "B/06_10_ColorSwitcher"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
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
            float4 _ColorA, _ColorB;
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

            #define TWO_PI 6.28318530718


            // rgb转换hsb
            float3 rgb2hsb(float3 c)
            {
                float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz),float4(c.gb, K.xy),step(c.b, c.g)); 
                float4 q = lerp(float4(p.xyw, c.r),float4(c.r, p.yzx),step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;

                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),d / (q.x + e),q.x);
            }

            // hsb转换rgb
            float3 hsb2rgb(float3 c)
            {
                float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
                rgb = rgb * rgb * (3.0 -2.0 * rgb);

                return c.z * lerp(1.0, rgb, c.y);
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

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float2 uv = i.uv;

                float3 color = float3(0.0, 0.0, 0.0);

                // Use polar coordinates instead of cartesian
                float2 toCenter = 0.5 - uv;

                float angle = atan2(toCenter.x, toCenter.y);
                float radius = length(toCenter)* 2.0;

                // Map the angle (-PI to PI) to the Hue (from 0 to 1)
                // and the Saturation to the radius
                color = 1 -  hsb2rgb(float3(((angle/TWO_PI)) + 0.5, radius, 1.0));

                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}