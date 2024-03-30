Shader "B/05_2DTikTok"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _ShineColor ("Shine Color", Color) = (1, 1, 1, 1) //光线的颜色
        _ShineLocation ("Shine Location", Range(0, 1)) = 0.5 //光线的位置
        _ShineRotate ("Rotate Angle(radians)", Range(0, 6.2831)) = 0 //2Π 360度
        _ShineWidth ("Shine Width", Range(0.05, 1)) = 0.1 //光线宽度
        _ShineGlow ("Shine Glow", Range(0, 100)) = 1 //光线亮度
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
            half4 _ShineColor;
            half _ShineLocation, _ShineRotate, _ShineWidth, _ShineGlow;
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

                half2 uvShine = i.uv;
				half cosAngle = cos(_ShineRotate);//分别计算光线旋转角度_ShineRotate的余弦值
				half sinAngle = sin(_ShineRotate);//分别计算光线旋转角度_ShineRotate的正弦值
				half2x2 rot = half2x2(cosAngle, -sinAngle, sinAngle, cosAngle);//创建一个二维旋转矩阵rot来旋转纹理坐标
				uvShine -= half2(0.5, 0.5);//将纹理坐标进行平移，使其以纹理的中心为原点 要让(0.5,0.5)的地方变成(0,0)
				uvShine = mul(rot, uvShine);//将纹理坐标按照旋转矩阵rot进行旋转
				uvShine += half2(0.5, 0.5);//将旋转后的纹理坐标恢复到原来的位置
				half currentDistanceProjection = (uvShine.x + uvShine.y) / 2;//计算当前像素在光线投影方向上的距离投影
				half whitePower = 1 - (abs(currentDistanceProjection - _ShineLocation) / _ShineWidth);//计算当前像素的亮度，用于模拟光线的强度
				col.rgb +=  col.a * whitePower * _ShineGlow * max(sign(currentDistanceProjection - (_ShineLocation - _ShineWidth)), 0.0)
				* max(sign((_ShineLocation + _ShineWidth) - currentDistanceProjection), 0.0) * _ShineColor;//计算出最终的颜色


                return col;
            }
            ENDHLSL
        }
    }
}