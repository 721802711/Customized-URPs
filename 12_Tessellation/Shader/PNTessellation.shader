Shader "B/PNTessellation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_NormalTex", 2D) = "bump"{}
        _HeightScale ("_HeightScale", Range(0.01,1)) = 0


        [KeywordEnum(integer, fractional_even, fractional_odd )]_Partitioning ("Partitioning Mode", Float) = 2
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1, 16)) = 4 
        _InsideFactor ("InsideFactor", Range(1, 16)) = 4 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _EdgeFactor; 
        float _InsideFactor; 
        float _HeightScale;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float3 normalOS : NORMAL;
        };

        // 第一个
        struct VertexOut 
        {
            float3 positionOS : INTERNALTESSPOS;     // 用于细分的内部顶点位置
            float2 texcoord : TEXCOORD0;
            float3 normal : NORMAL;
        };

        struct PatchTess
        {
            float edgeFactor[3] : SV_TESSFACTOR;       // 表示这是一个细分因子
            float insideFactor : SV_INSIDETESSFACTOR;  // 内部细分因子
        };

        struct HullOut
        {
            float3 positionOS : INTERNALTESSPOS;       // 用于细分的内部顶点位置
            float2 texcoord : TEXCOORD0;
            float3 normal : NORMAL; // 传递法线信息
            float3 positionOS1 : TEXCOORD1; // 三角片元每个顶点多携带两个顶点信息
            float3 positionOS2 : TEXCOORD2;
        };


        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL;
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM

            #pragma target 4.6 

            #pragma vertex vert                         // 顶点着色器
            #pragma hull PNTessControlPoint             // 曲面着色器
            #pragma domain PNTessDomain                 // 域着色器
            #pragma fragment frag                       // 片段着色器

            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD   
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 

            //  ==========================================================================================================================================

            // 模型顶点传入到 VertexOut结构体
            VertexOut vert(appdata v)           
            {
                VertexOut o;
                o.positionOS = v.positionOS.xyz;
                o.texcoord = v.texcoord; 
                o.normal.xyz = TransformObjectToWorldNormal(v.normalOS.xyz); // 计算世界空间法线;
                return o;
            }


            //  曲面着色器常量函数
            PatchTess PatchConstant(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
            {
                PatchTess o;

                o.edgeFactor[0] = _EdgeFactor;
                o.edgeFactor[1] = _EdgeFactor;
                o.edgeFactor[2] = _EdgeFactor;
                o.insideFactor = _InsideFactor;

                return o;
            }
            
            //  ==========================================================================================================================================
            float3 ComputeCP(float3 pA, float3 pB, float3 nA){
                return (2 * pA + pB - dot((pB - pA), nA) * nA) / 3.0f;
            }



            // 设置细分属性

            [domain("tri")]   
            #if _PARTITIONING_INTEGER
            [partitioning("integer")] 
            #elif _PARTITIONING_FRACTIONAL_EVEN
            [partitioning("fractional_even")] 
            #elif _PARTITIONING_FRACTIONAL_ODD
            [partitioning("fractional_odd")]    
            #endif 

            #if _OUTPUTTOPOLOGY_TRIANGLE_CW
            [outputtopology("triangle_cw")] 
            #elif _OUTPUTTOPOLOGY_TRIANGLE_CCW
            [outputtopology("triangle_ccw")] 
            #endif


            [patchconstantfunc("PatchConstant")] // 细分常量函数：PatchConstant
            [outputcontrolpoints(3)] // 输出控制点数量：3
            [maxtessfactor(64.0f)] // 最大细分因子：64.0


            //  ==========================================================================================================================================
            // 曲面着色器阶段
            HullOut PNTessControlPoint (InputPatch<VertexOut, 3> patch, uint id : SV_OutputControlPointID)
            {
                HullOut o;
                const uint nextCPID = id < 2 ? id + 1 : 0;  // 下一个控制点的索引


                o.positionOS = patch[id].positionOS;
                o.texcoord = patch[id].texcoord;
                o.normal = patch[id].normal; // 传递法线

                o.positionOS1 = ComputeCP(patch[id].positionOS, patch[nextCPID].positionOS, patch[id].normal);
                o.positionOS2 = ComputeCP(patch[nextCPID].positionOS, patch[id].positionOS, patch[nextCPID].normal);
                return o;

            }

            // 域着色器
            [domain("tri")]   // 
            v2f PNTessDomain (PatchTess tessFactors, const OutputPatch<HullOut, 3> patch, float3 bary : SV_DOMAINLOCATION)
            {



                // u, v, w 代表 重心坐标
                float u = bary.x;
                float v = bary.y;
                float w = bary.z;

                // 重心坐标的平方和立方
                float uu = u * u;
                float vv = v * v;
                float ww = w * w;
                float uu3 = 3 * uu;
                float vv3 = 3 * vv;
                float ww3 = 3 * ww;

                // 输入修补程序中的控制点位置
                float3 b300 = patch[0].positionOS;
                float3 b210 = patch[0].positionOS1;
                float3 b120 = patch[0].positionOS2;
                float3 b030 = patch[1].positionOS;
                float3 b021 = patch[1].positionOS1;
                float3 b012 = patch[1].positionOS2;
                float3 b003 = patch[2].positionOS;
                float3 b102 = patch[2].positionOS1;
                float3 b201 = patch[2].positionOS2;  


                // 三角形中心控制点的位置
                float3 E = (b210 + b120 + b021 + b012 + b102 + b201) / 6.0;
                // 三角形三个顶点位置的平均值
                float3 V = (b003 + b030 + b300) / 3.0; 
                // 三角形中心控制点的位置
                float3 b111 = E + (E - V) / 2.0f;  

                // 插值获得细分后的顶点位置
                float3 positionOS = b300 * uu * u + b030 * vv * v + b003 * ww * w 
                    + b210 * uu3 * v 
                    + b120 * vv3 * u
                    + b021 * vv3 * w
                    + b012 * ww3 * v
                    + b102 * ww3 * u
                    + b201 * uu3 * w
                    + b111 * 6.0 * w * u * v;


                // 插值法线
                float3 interpolatedNormal = patch[0].normal * u +  patch[1].normal * v +  patch[2].normal * w;
                // UV
                float2 texcoord = patch[0].texcoord * u + patch[1].texcoord * v + patch[2].texcoord * w;

                // 采样高度图
                float height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, texcoord, 1.0).r; // 假设高度值存储在红色通道
                height =  height * _HeightScale - _HeightScale / 2.0;

                // 顶点应用法线方向和高度图
                positionOS.xyz += interpolatedNormal * height;


                v2f output;

                output.positionCS = TransformObjectToHClip(positionOS);    // 世界坐标转换到裁剪空间
                output.uv = texcoord;                                 // 纹理坐标
                output.normalWS = normalize(interpolatedNormal); // 输出插值的法线
                return output;
            }


            half4 frag (v2f i) : SV_Target
            {
                half4 diffuseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                Light mainLight = GetMainLight();

                half NdotL = saturate(dot(i.normalWS, mainLight.direction) * 0.5 + 0.5);
                half3 col = diffuseColor.rgb * mainLight.color * NdotL;

                return half4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
