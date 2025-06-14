Shader "B/10_05_MatCap_Correction"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "bump"{}
        _NormalMap ("Normal Map", 2D) = "bump" {} // 新增法线贴图属性
        _MatCap("Mat Cap", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
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
                float2 uv : TEXCOORD0;                                             //float4类型的UV数据，
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD2;                                     //输出世界空间下位置 
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
                float4 tangentWS :TANGENT;                                         //注意 是 float4 类型，W分量储存其他信息
            };


        TEXTURE2D(_MatCap);                          SAMPLER(sampler_MatCap);
        TEXTURE2D(_MainTex);                         SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap);                       SAMPLER(sampler_NormalMap); // 声明法线贴图
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag



            float3 ObjectToWorldNormal(float3 normalOS)
            {
                return normalize(mul((float3x3)unity_WorldToObject, normalOS));
            }


            float3 ObjectToViewPos(float3 positionWS)
            {
                return mul(UNITY_MATRIX_V, float4(positionWS, 1.0)).xyz;
            }

            // 修复 MatCapUV 函数
            float2 MatCapUV(float3 N, float3 ViewPos)
            {
                float3 viewCross = cross(ViewPos, N);
                float3 viewNorm = float3(-viewCross.y, viewCross.x, 0.0);

                float2 matCapUV = viewNorm.xy * 0.5 + 0.5;
                return matCapUV;
            }

            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = NormalInputs.normalWS;
                o.tangentWS = float4(NormalInputs.tangentWS, v.tangentOS.w);


                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);                               

                return o;   

            }


            half4 frag (v2f i) : SV_Target
            {

                // 从法线贴图中采样法线向量
                half4 normalMapSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                half3 normalTS = UnpackNormalScale(normalMapSample, 1.0); // 转换法线贴图的颜色值到实际的法线向量

                // 构造切线矩阵
                float3 t = normalize(i.tangentWS.xyz);
                float3 n = normalize(i.normalWS); // 这里使用从顶点着色器传递来的世界空间法线
                float3 b = cross(n, t) * i.tangentWS.w;
                float3x3 tangentMatrix = float3x3(t, b, n);


                // 使用切线矩阵将切线空间的法线转换为世界空间
                half3 normalWS = TransformTangentToWorld(normalTS, tangentMatrix);

                // 基础方法
                float2 UVandMatCap;
                UVandMatCap.x = dot(normalize(UNITY_MATRIX_IT_MV[0].xyz), normalize(normalWS));
				UVandMatCap.y = dot(normalize(UNITY_MATRIX_IT_MV[1].xyz), normalize(normalWS));


                // 使用切线空间的法线计算MatCap的UV坐标
                UVandMatCap = UVandMatCap.xy * 0.5 + 0.5; 

                // 模型 物体不居中的时候产生拉伸变形 需要进行矫正
                // 矫正方法
                float3 N = normalize(ObjectToWorldNormal(normalWS));
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                float2 matCapUV = MatCapUV(N, viewDirWS);

                half3 matCapColor = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, UVandMatCap).rgb; 
            
                half4 diffuse_color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);   

                half4 finalColor = half4(matCapColor * diffuse_color.rgb * 2.0, 1);

                return finalColor;
            }
            ENDHLSL
        }
    }
}