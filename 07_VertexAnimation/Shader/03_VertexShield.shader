Shader "B/03_VertexShield"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [KeywordEnum(XAxis, YAxis, ZAxis,)] _Dir ("Anim Direction", float) = 0

        _Scale("_Scale",Range(-1.0,1.0)) = 1
        _Int ("_Int", Range(0,1.0)) = 0.1
        _Blur ("_Blur" , Range(0,1.0)) = 0.5


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _Scale, _Int, _Blur, _ShineRotate;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);

        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #pragma multi_compile _ _DIR_XAXIS _DIR_YAXIS _DIR_ZAXIS

            float Stroke(float x, float s, float w, float b)
            {
                
                float d = smoothstep(s,s + b ,x + w * 0.5 ) - smoothstep(s,s + b, x - w * 0.5);

                return clamp(d, 0.0, 1.0);
            }



            v2f vert (appdata v)
            {
                v2f o;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

                float saturate = 0.0;
                #if _DIR_XAXIS 
                    saturate =  (o.normalWS.x + 1) * 0.5;  
                #elif _DIR_YAXIS
                    saturate =  (o.normalWS.y + 1) * 0.5;  
                #elif _DIR_ZAXIS
                    saturate =  (o.normalWS.z + 1) * 0.5;  
                #endif
                saturate -= _Scale;

                // 顶点动画
                float pct = Stroke(saturate - _Int, 0.0, _Int, _Blur);  // 这里便宜我们需要计算 int的宽度，要不收尾的时候有边。


                v.positionOS.xyz += v.normalOS.xyz * pct * 0.1;
                
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置



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