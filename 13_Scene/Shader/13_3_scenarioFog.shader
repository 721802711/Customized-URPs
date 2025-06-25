Shader "B/13_3_scenarioFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SoftFade("_SoftFade",Float) = 1.0
        _FogColor("_FogColor",Color) = (1,1,1,1)
        _Soft("_Soft",Range(0,3)) = 1.0


        _fadeInt ("_fadeInt",Range(1,3)) = 1.0
        _MaskTex ("MaskTex", 2D) = "white" {}
        _UVSpeedRG("UV Speed (R_xy, G_zw)", Vector) = (0.2, 0.0, 0.1, 0.0) // xy: Rͨ��UV�ٶȣ�zw: Gͨ��UV�ٶ�

        _Niose_R_Tiling("_Niose_R_Tiling", Float) = 1.0
        _Niose_G_Tiling("_Niose_G_Tiling", Float) = 1.0
        _Blend("_Blend",Float) = 1.0
        _MaskTexAlpha("_MaskTexAlpha",Range(0,1)) = 1.0

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"  "Queue"="Transparent"}
        Blend[_SrcBlend][_DstBlend]

        Cull Off
        ZWrite Off

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _MaskTex_ST;
        float _SoftFade,_Soft, _Niose_R_Tiling,_Niose_G_Tiling, _Blend;
        float4 _FogColor;
        float4 _UVSpeedRG;
        float _fadeInt,_MaskTexAlpha;
        CBUFFER_END

        struct appdata
        {
            float3 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord :TEXCOORD0; 
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL;
            float3 positionWS:TEXCOORD1;
            float4 scrPos : TEXCOORD0;
            float4 uv : TEXCOORD2;   
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);                          SAMPLER(sampler_MaskTex);

        TEXTURE2D(_CameraDepthAttachment);
        SAMPLER(sampler_CameraDepthAttachment);

        ENDHLSL


        Pass
        {


            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
                o.positionWS = PositionInputs.positionWS;                                      

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS.xyz = NormalInputs.normalWS;                                  

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);  
                o.scrPos = ComputeScreenPos(o.positionCS);    
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float2 ndcPos  = i.scrPos.xy/ i.scrPos.w;                                                        // [0-1] ͸�ӳ���
                float depth = SAMPLE_TEXTURE2D(_CameraDepthAttachment,sampler_CameraDepthAttachment,ndcPos).r;         // [-w,w] ������� 
                float LinearDepth = LinearEyeDepth(depth,_ZBufferParams);                                        
 

                float fade = saturate((LinearDepth - i.scrPos.w - _Soft) / _SoftFade);      


                float2 uv1 = i.uv.xy * _Niose_R_Tiling + UVSpeed(_UVSpeedRG.x,_UVSpeedRG.y);
                float2 uv2 = i.uv.xy * _Niose_G_Tiling + UVSpeed(_UVSpeedRG.z,_UVSpeedRG.w);

                half Tex1 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv1).r;             
                half Tex2 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv2).g;



                half mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv.xy).r * _MaskTexAlpha;

                // �ںϳ���
                half  texblend = clamp(0,1,lerp(Tex1,(Tex1 * Tex2),_Blend));



                float4 col;

                col.rgb = ((fade * _fadeInt)  + (fade * texblend * _FogColor.a)) * _FogColor.rgb;
                col.a = clamp(0,1,fade) * mask * _FogColor.a;



                return col;
            }
            ENDHLSL
        }
    }
}