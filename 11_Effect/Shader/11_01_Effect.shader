Shader "B/11_01_Effect"
{
    Properties
    {
        [HDR]_BaseColor("BaseColor",Color)=(1,1,1,1)
        _Alpha ("Alpha", Range(0,1)) = 1
        _MainTex("MainTex",2D)="White"{}
        [Toggle(Channel)] Channel ("R or A ", Float ) = 0
        _glow("_glow",Range(1.0,10)) = 1.0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
    }
    SubShader
    {
        Tags{  "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend[_SrcBlend][_DstBlend]

        Cull Off
        ZWrite Off

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        half _glow,_Alpha;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS:POSITION;
                float2 texcoord:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float2 uv:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ Channel 
        
            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.vertexColor = v.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                half a = i.vertexColor.a * _BaseColor.a * _Alpha;

            #if Channel                                                                    
                half4 col = (tex.a * _BaseColor * _glow) * a;
            #else 
                half4 col = (tex.r * _BaseColor * _glow) * a;
            #endif

                return col;
            }
            ENDHLSL
        }
    }
}