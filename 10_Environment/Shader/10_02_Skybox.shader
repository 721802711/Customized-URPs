Shader "B/10_02_Skybox"
{
    Properties
    {
		[HDR]_Top("Top", Color) = (1,1,1,0)
		[HDR]_Bottom("Bottom", Color) = (0,0,0,0)
		_mult("mult", Float) = 1
		_pwer("pwer", Float) = 1

        [KeywordEnum(Gradient,Circle,pos_x, pos_z)] _Scr ("Screen space", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _Bottom,_Top;
            float _mult,_pwer;

        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
				float4 positionOS : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _SCR_GRADIENT  _SCR_CIRCLE _SCR_POS_X _SCR_POS_Z


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.screenPos = ComputeScreenPos(o.positionCS);                   //屏幕空间
				o.positionOS = v.positionOS;                                     //输出顶点
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float4 screenPos = i.screenPos;
                float2 screenPosNorm = screenPos.xy / screenPos.w;


                #if _SCR_GRADIENT
                    float staticSwitch = screenPosNorm.y;
                #elif _SCR_CIRCLE
                    float staticSwitch = i.positionOS.y;

                #elif _SCR_POS_X
                    float staticSwitch = i.positionOS.x;
                #elif _SCR_POS_Z
                    float staticSwitch = i.positionOS.z;
                #endif

                half4 col = lerp(_Bottom,_Top, pow(saturate(staticSwitch * _mult),_pwer));     

                return col;
            }
            ENDHLSL
        }
    }
}