Shader "DFW/Scenes/AlphaBlend_Cull"
{
    Properties
    {
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_Bright ("Brightness", Range(0,5)) = 2.0
		[Enum(Double Side, 0, Back, 2)] _Cull ("Culling Mode", Float) = 2
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }

		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask RGB
		Cull [_Cull] Lighting Off ZWrite Off

        Pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _TintColor;
                float _Bright;
                float _Cull;
            CBUFFER_END


            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);


            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 texcord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;

            };

            Varyings vert(Attributes input)
            {
                Varyings o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.color = input.color;
                o.uv = TRANSFORM_TEX(input.texcord, _MainTex);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 col = i.color * _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);


                return col;
            }

            ENDHLSL
        }
    }

}
