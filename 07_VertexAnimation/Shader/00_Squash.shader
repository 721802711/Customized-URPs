Shader "B/00_Squash"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _TopY ("Top Y", Float) = 1
        _BottomY ("Bottom Y", Float) = 0
        _Control ("Control", Range(0, 1)) = 0

        [Space(20)]     
		[Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _TopY;
            half _BottomY;
            half _Control;
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

            float GetNormalizeDist(float worldY)
            {
                float range = _TopY - _BottomY;
                float distance = _TopY - worldY;
                
                return saturate(distance / range);
            }


            v2f vert (appdata v)
            {
                v2f o;

                float normalizeDist = GetNormalizeDist(v.positionOS.y);

                float3 localNegativeY = TransformWorldToObjectDir(float3(0, -1, 0));
                float value = saturate(_Control - normalizeDist);
                v.positionOS.xyz += localNegativeY * value;
                
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                return col;
            }
            ENDHLSL
        }
    }
}