Shader "B/00_VertexAnimAtion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [KeywordEnum(None, Translate, Scale, Rotate,)] _Dir ("Anim Direction", float) = 0

        _MoveSpeed ("Move Speed" , Float) = 1
        _MoveRange ("Move Range" , Float) = 1

        _RotateRange("Rotate Range", Range(0, 180)) = 0

        [Space(20)]     
		[Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _MoveSpeed, _MoveRange, _RotateRange;
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

            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            //# define TWO_PI 6.283185        // PI 360度

            #pragma multi_compile _ _DIR_TRANSLATE _DIR_SCALE _DIR_ROTATE

            // 平移函数
            float3 Translation(float3 positionCS)
            {
                positionCS.y += _MoveRange * sin(frac(_Time.z * _MoveSpeed) * TWO_PI);
                return positionCS;
			}

            // 缩放函数
            float3 Scale(float3 positionOS)
            {
                // 局部空间
                positionOS *= 1.0 + sin(frac(_Time.y * _MoveSpeed) * TWO_PI) * _MoveRange;
                
                return positionOS;
            }
            // 旋转函数
            float3 Rotation(float3 positionOS, float Range, float Speed)
            {
                // 根据时间、旋转速度和旋转范围计算出一个角度angleY
                float angleY = Range * sin(frac(_Time.y * Speed) * TWO_PI); 
                float radianY = radians(angleY);            // 将角度angleY转换成弧度radianY，

                float sin_radianY , cos_radianY = 0.0;   

                sincos(radianY, sin_radianY, cos_radianY);    

                //创建一个2x2的旋转矩阵Rotate_Matrix_Y，用于绕Y轴进行旋转
                float2x2 Rotate_Matrix_Y = float2x2(cos_radianY,sin_radianY, - sin_radianY, cos_radianY);
                 // 将传入的位置positionOS的X和Z分量与旋转矩阵相乘，得到旋转后的新位置
                positionOS.xz = mul(Rotate_Matrix_Y, float2(positionOS.x, positionOS.z));
                
                return positionOS;
            }


            v2f vert (appdata v)
            {
                v2f o;

                float3 objectPos = v.positionOS.xyz;
                #if _DIR_TRANSLATE 
                    objectPos = Translation(v.positionOS.xyz);  // 对象空间
                #elif _DIR_SCALE
                    objectPos = Scale(v.positionOS.xyz);
                #elif _DIR_ROTATE
                    objectPos = Rotation(v.positionOS.xyz, _RotateRange, _MoveSpeed);
                #endif


                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(objectPos); // 获取顶点位置输入
                o.positionCS = PositionInputs.positionCS;    // 转换到齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

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