Shader "B/00_Matrices_Box"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [KeywordEnum(BasicSquare, FunctionSquare, Blur, SquareSide, Rectangle, BlurRectangle)] _Dir ("Anim Direction", float) = 0
        _Scale("_Scale",Range(0,1)) = 1
        _Length ("_Length", Range(0,1)) = 0.1
        _Width ("_Width", Range(0,1)) = 0.1
        _Blur ("_Blur", Range(0,0.1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _Scale, _Length,_Width, _Blur;
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


            #pragma multi_compile _ _DIR_BASICSQUARE _DIR_FUNCTIONSQUARE _DIR_BLUR _DIR_SQUARESIDE _DIR_RECTANGLE _DIR_BLURRECTANGLE


            // 长方形 
            float Stroke(float x, float s, float w)
            {
                float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);

                return clamp(d, 0.0, 1.0);
            }

            float StrokeS(float x, float s, float w, float b)
            {
                float d = smoothstep(s,s + b ,x + w * 0.5 ) - smoothstep(s,s + b, x - w * 0.5);

                return clamp(d, 0.0, 1.0);
            }


            // 基础正方形
            float BoxA(float x, float s, float2 uv)
            {
                float2 bl = step(x, uv);
                float2 tr = step(s, 1- uv);

                float pct = bl.x * bl.y * tr.x * tr.y;
                return clamp(pct, 0.0, 1.0);
            }

            // 调整 数值
            float BoxB(float2 _st, float2 size)
            {
                size = 0.5 - (1 - size) * 0.5;     // 从 [0 - 0.5]映射到 [0 - 1] 之间

                float2 uv = step(size, _st);
                uv *= step(size, 1 - _st);
                return uv.x * uv.y;
            }


            // 定义边缘虚化正方形
            float BoxC(float2 _st, float2 _size, float blur)
            {
                float2 size = 0.5 - _size * 0.5;
                float2 uv = smoothstep(size,size + blur,_st);
                uv *= smoothstep(size, size + blur,1.0 - _st);
                return uv.x * uv.y;
            }


            v2f vert (appdata v)
            {
                v2f o;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

                
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置



                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = float4(0.0,0.0,0.0,0.0);

                float2 uv = i.uv;

                float Mat = 0.0;
                // 基础 BOX
                #if _DIR_BASICSQUARE 
                    Mat =  BoxA(_Length, _Width, uv);
                #elif _DIR_FUNCTIONSQUARE
                    Mat = BoxB(uv, _Scale);
                #elif _DIR_BLUR
                    Mat = BoxC(uv, _Scale, _Blur);
                #elif _DIR_SQUARESIDE
                    Mat = BoxB(uv, _Scale- 0.2) - BoxB(uv, _Scale);
                #elif _DIR_RECTANGLE
                    Mat = Stroke(uv, _Width, _Length);
                #elif _DIR_BLURRECTANGLE
                    Mat = StrokeS(uv, _Width, _Length, _Blur);
                #endif

                col += Mat;
                //col += pct;

                return col;
            }
            ENDHLSL
        }
    }
}