Shader "B/11_02_UVMask"
{
    Properties
    {
        _BaseColor("_BaseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex("_MaskTex",2D) = "white" {}
        _U ("U", Float ) = -1
        _V ("V", Float ) = 0
        [MaterialToggle] _Toggle ("Toggle", Float ) = 0
        _UV ("_UV",Range(-1.0,1.0)) = 0.0
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
            float4 _MainTex_ST,_MaskTex_ST;
            float4 _BaseColor;
            half _U,_V, _UV, _Toggle;
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
            TEXTURE2D (_MaskTex);                         SAMPLER(sampler_MaskTex);

        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

        
            //定义一个UV速度函数
            half2 UVSpeed(half speedU,half speedV)
            {
                half2 uvSpeed = _Time.y * (half2(speedU,speedV));
                return uvSpeed;
			}

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

                float2 uv = UVSpeed(_U,_V) + i.uv;
                float2 onetimeUV = float2( _UV * _U,_UV * _V);   

                float2 TexUV = lerp(uv, (i.uv + onetimeUV), _Toggle);   

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,TexUV) * _BaseColor * i.vertexColor;     
                float Mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv).r;   
                
                float alpha = Mask *  i.vertexColor.a * _BaseColor.a;


                return half4(col.rgb, alpha);
            }
            ENDHLSL
        }
    }
}