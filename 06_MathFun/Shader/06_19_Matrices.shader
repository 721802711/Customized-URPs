Shader "B/06_19_Matrices"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _cull ("cull Mode", Float) = 0 
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}

        LOD 100


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

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

            #define PI 3.14159265359

            float Box(float2 _st, float2 _size)
            {
                float2 size = 0.5 - _size * 0.5;
                float2 uv = smoothstep(size,size + 0.001,_st);
                uv *= smoothstep(size, size + 0.001,1.0 - _st);
                return uv.x * uv.y;
            }

            float Cross(float2 _st, float _size)
            {
                float box = Box(_st, float2(_size,_size/4.0)) + Box(_st, float2(_size/4.0,_size));
                return  box;
            }

            float2x2 Rotate2d(float _angle)
            {
                return float2x2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
            }

            
            float2x2 Scale(float2 _scale)
            {
                
                return float2x2(_scale.x,0.0,0.0,_scale.y);
            }


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float2 uv = i.uv;


                float3 color = float3(0.0, 0.0, 0.0);
                

                // 定义缩放因子
                float2 scale = float2(sin(_Time.y) + 1.0, sin(_Time.y) + 1.0); // 例如，基于时间的缩放

                float2 st = i.uv - 0.5;
                st = mul(Scale(scale), st); // 使用 mul 函数进行矩阵与向量的乘法
                st += 0.5;



                // Add the shape on the foreground
                color.rgb += Cross(st,0.4);
                return float4(color.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}