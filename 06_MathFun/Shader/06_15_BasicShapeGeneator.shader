Shader "B/06_15_BasicShapeGeneator"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Dis ("Dis", Range(1, 30)) = 1
        _Visualize ("Visualize", Range(1, 30)) = 2

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
            float _Dis, _Visualize;
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

                float2 pos = 0.5 - uv;

                float r = length(pos) * 2.0;
                float a = atan2(pos.y, pos.x);

                float f = cos(a * 3);

                color = 1.0 - smoothstep(f, f+ 0.02, r);
                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}