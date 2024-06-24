Shader "B/11_13_Air_Distortion"
{
    Properties
    {
        _MainTex("MainTex",2D)="White"{}
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		_HeatTime  ("Heat Time", range (0,1)) = 0.1
		_HeatForce  ("Heat Force", range (0,0.1)) = 0.008


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
            float4 _MainTex_ST, _NoiseTex_ST;
			float _HeatForce;
			float _HeatTime;
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
                float4 uv:TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);                          SAMPLER(sampler_NoiseTex);
            SAMPLER(_CameraOpaqueTexture);
            SAMPLER(_CameraColorTexture);
        ENDHLSL


        Pass
        {
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

                half4 tex_mask = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);

				//noise effect
				half4 offsetTex1 = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv.xy + _Time.xz * _HeatTime);
				half4 offsetTex2 = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv.xy - _Time.xz * _HeatTime);

				half distortX = ((offsetTex1.r + offsetTex2.r) - 1) * _HeatForce;
				half distorty = ((offsetTex1.g + offsetTex2.g) - 1) * _HeatForce;


				half2 screenUV = (i.positionCS.xy / _ScreenParams.xy) + float2(distortX, distorty);

                half4 screen = tex2D(_CameraOpaqueTexture, screenUV);
                screen.a *= tex_mask.r;
                
                return screen;
            }
            ENDHLSL
        }
    }
}