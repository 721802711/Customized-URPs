Shader "B/LightBaked" //URP路径名
{
     //面板属性
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
        SubShader
        {
			//渲染类型为URP
           Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"}
			//多距离级别
            LOD 100 

		 Pass
        {

            HLSLPROGRAM  //URP 程序块开始

			//顶点程序片段 vert
			#pragma vertex vert

			//表面程序片段 frag
            #pragma fragment frag


			#pragma multi_compile _ LIGHTMAP_ON


			//URP函数库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial) //变量引入开始

            CBUFFER_END //变量引入结束



			//定义模型原始数据结构
            struct VertexInput          
            {
				//获取物体空间顶点坐标
                float4 positionOS : POSITION; 

				//获取模型UV坐标
                float2 uv : TEXCOORD0;
				float2 LightmapUV : TEXCOORD1;
					//模型法线
				float4 normalOS  : NORMAL;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
            };


			//定义顶点程序片段与表i面程序片段的传递数据结构
            struct VertexOutput 
            {
			   //物体视角空间坐标
                float4 positionCS : SV_POSITION; 
				
				//UV坐标
                float2 uv : TEXCOORD0;

				//世界空间顶点
				float3 positionWS :  TEXCOORD1;
				//世界空间法线
				float3 normalWS : TEXCOORD2;
				float2 staticLightmapUV : TEXCOORD3;

				float3 vertexSH   : TEXCOORD4;
            };

				//顶点程序片段
                VertexOutput vert(VertexInput v)
                {
				   //声明输出变量o
                    VertexOutput o;


					//输入物体空间顶点数据
					VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
					//获取裁切空间顶点
                    o.positionCS = positionInputs.positionCS;
					//获取世界空间顶点
					o.positionWS = positionInputs.positionWS;
					
					//输入物体空间法线数据
					VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);

					//获取世界空间法线
					o.normalWS = normalInputs.normalWS;

					OUTPUT_LIGHTMAP_UV(v.LightmapUV, unity_LightmapST, o.staticLightmapUV);

					//输出数据
                    return o;
                }

				//表面程序片段
                float4 frag(VertexOutput i): SV_Target 
                {

				//贴图法线转换为世界法线
				float3 normalWS = i.normalWS;

				half3 bakedGI = SAMPLE_GI(i.staticLightmapUV, i.vertexSH, normalWS);

				return float4(bakedGI,1);

			}
            ENDHLSL  //URP 程序块结束          
        }
    }
}