Shader "B/11_04_Dissolve_Basic"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeWidth ("Edge Width", Range(0.01, 0.5)) = 0.1
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent" "IgnoreProjector" = " True"  }
        Cull Off
        LOD 100
        Blend[_SrcBlend][_DstBlend]
        ZWrite Off

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            half _Threshold, _EdgeWidth;
            float _Soft;
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
                float4 uv:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);

        ENDHLSL

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                o.vertexColor = v.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {


                
                float cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r;

                float dis = saturate(cutout+ 1.05 + (_Threshold * -1.0));
                half edgeWidth = _EdgeWidth * 0.5;             // 根据边缘宽度调整smoothstep的范围
                half dis_soft = smoothstep(1.0 - edgeWidth, 1.0 + edgeWidth, dis);
                dis_soft *= 2;

                half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).xyz;
                float alpha = dis_soft;

                return half4(col,alpha);
            }
            ENDHLSL
        }
    }
}