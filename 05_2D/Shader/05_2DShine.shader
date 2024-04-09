Shader "B/05_2DShine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _Min ("_Min", Range(0,1)) = 0.0
        _Max ("_Max", Range(0,1)) = 1.0
        _ShineColor ("Shine Color", Color) = (1, 1, 1, 1) //光线的颜色
        _ShineRotate ("Rotate Angle(radians)", Range(0, 6.2831)) = 0 //2Π 360度
        _ShineLocation ("Shine Location", Range(-1, 1)) = 0.5 //光线的位置

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
            float _Min, _Max, _ShineRotate, _ShineLocation;
            float4 _ShineColor;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
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

            float4 SampleMainTex(float2 uv)
            {
                // 采样主贴图
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }

            float2x2 Rotate2d(float _angle)
            {
                return float2x2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
            }



            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.color = v.color;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SampleMainTex(i.uv);

                half2 uv = i.uv;

                // 旋转函数
                float2 st = uv - 0.5;
                st = mul(Rotate2d(_ShineRotate), st); // 使用mul函数进行矩阵乘法
                st += 0.5;

                // 平移
                st = clamp(0.0, st +  _ShineLocation, 1.0);

                // 渐变图形
                float2 uvShine = smoothstep(_Min,_Max,st.x) - smoothstep(_Min,_Max + 0.2,st.x);
                float Shine = uvShine.x * uvShine.y;

                // 输出颜色
                col.rgb +=  col.a * Shine * _ShineColor * _ShineColor.a;

                return col;
            }
            ENDHLSL
        }
    }
}