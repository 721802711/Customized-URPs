Shader "B/06_07_ColorSwitcher"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _ColorA ("_ColorA" ,COLOR) = (1,1,1,1)
        _ColorB ("_ColorB" ,COLOR) = (1,1,1,1)

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

            // Plot a line 
            float plot(float2 uv, float pct)
            {
                return smoothstep(pct - 0.02, pct, uv.y) - smoothstep(pct, pct + 0.02, uv.y);
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


                float pct = uv.x;

                // Mix 函数 和 Lerp函数一样
                float3 color = lerp(_ColorA,_ColorB, pct);

                // Plot 

                color = lerp(color, float3(1.0, 0.0, 0.0), plot(uv, pct));



                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}