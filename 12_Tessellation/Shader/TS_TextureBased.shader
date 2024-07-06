Shader "B/TS_TextureBased"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}
        _HeightScale ("_HeightScale", Range(0.01,1)) = 0


        [KeywordEnum(integer, fractional_even, fractional_odd )]_Partitioning ("Partitioning Mode", Float) = 2
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1, 8)) = 4 
        _InsideFactor ("InsideFactor", Range(1, 8)) = 4 
        _PhoneShape ("PhoneShape", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Tessellation.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _EdgeFactor; 
        float _InsideFactor; 
        float _HeightScale;
        float _PhoneShape;
        float _TessMinDist;
        float _FadeDist;
        CBUFFER_END

        struct appdata
        {
            float3 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
        };

        // 第一个
        struct VertexOut 
        {
            float3 positionWS : INTERNALTESSPOS;     // 用于细分的内部顶点位置
            float2 texcoord : TEXCOORD0;
            float3 normalWS : NORMAL;
        };

        struct PatchTess
        {
            float edgeFactor[3] : SV_TESSFACTOR;       // 表示这是一个细分因子
            float insideFactor : SV_INSIDETESSFACTOR;  // 内部细分因子
        };

        struct HullOut
        {
            float3 positionWS : INTERNALTESSPOS;       // 用于细分的内部顶点位置
            float2 texcoord : TEXCOORD0;
            float3 normalWS : NORMAL; // 传递法线信息
        };


        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 normalWS : TEXCOORD1;
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert                         // 顶点着色器
            #pragma hull PhoneTriControlPoint             // 曲面着色器
            #pragma domain PhoneTriTessDomain                 // 域着色器
            #pragma fragment frag                       // 片段着色器

            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD   
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 

            //  ==========================================================================================================================================

            // 模型顶点传入到 VertexOut结构体
            VertexOut vert(appdata v)           
            {
                VertexOut o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS);
                o.positionWS = PositionInputs.positionWS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

                o.texcoord = v.texcoord; 
                return o;
            }

            // ==========================================================================================================================================
            float4 CalcHightTessFactors(float triVertexFactors)
            {
                real4 tess;
                tess.x = triVertexFactors.x;
                tess.y = triVertexFactors.x;
                tess.z = triVertexFactors.x;
                tess.w = (triVertexFactors.x + triVertexFactors.x + triVertexFactors.x) / 3.0;

                return tess;
            }

            // 曲面着色器常量函数
            PatchTess PatchConstant(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
            {
                PatchTess o;

                // 初始化一个变量来存储高度图的总值
                float totalHeight = 0.0;

                // 对patch中的每个顶点进行遍历，采样高度图并累加高度值
                for (int i = 0; i < 3; ++i)
                {
                    float heightSample = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, patch[i].texcoord, 0).r;
                    totalHeight += heightSample;
                }

                float4 tessFactors = _EdgeFactor * CalcHightTessFactors(totalHeight); // 计算细分因子;

                // 应用计算得到的动态细分因子
                o.edgeFactor[0] = max(1.0, tessFactors.x); // 边缘细分因子;
                o.edgeFactor[1] = max(1.0, tessFactors.y); // 边缘细分因子;
                o.edgeFactor[2] = max(1.0, tessFactors.z); // 边缘细分因子;

                o.insideFactor = max(1.0, tessFactors.w); // 内部细分因子

                return o;
            }
            //  ==========================================================================================================================================

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
            HullOut PhoneTriControlPoint (InputPatch<VertexOut, 3> patch, uint id : SV_OutputControlPointID)
            {
                HullOut o;

                o.positionWS = patch[id].positionWS;
                o.texcoord   = patch[id].texcoord;
                o.normalWS   = patch[id].normalWS; // 传递法线

                return o;

            }

            // 域着色器
            [domain("tri")]
            v2f PhoneTriTessDomain(PatchTess tessFactors, const OutputPatch<HullOut, 3> patch, float3 bary : SV_DOMAINLOCATION)
            {
                // 重心坐标下的插值
                float u = bary.x;
                float v = bary.y;
                float w = bary.z;
                
                // 插值位置和法线
                float3 posWS = u * patch[0].positionWS + v * patch[1].positionWS + w * patch[2].positionWS;
                float3 normalWS = normalize(u * patch[0].normalWS + v * patch[1].normalWS + w * patch[2].normalWS);
                
                // 计算高度映射的调整
                float2 texcoord = u * patch[0].texcoord + v * patch[1].texcoord + w * patch[2].texcoord;
                // 应用高度图调整顶点位置（模拟PN-AEN效果）
                float height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, texcoord, 0).r;
                float3 adjustedPosWS = posWS + normalWS * _HeightScale * (height - 0.5);
                

                v2f output;
                output.positionCS = TransformWorldToHClip(adjustedPosWS);
                output.uv = texcoord;
                output.normalWS = normalWS;

                return output;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 diffuseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                
                
                Light mainLight = GetMainLight();

                half NdotL = saturate(dot(i.normalWS, mainLight.direction) * 0.5 + 0.5);
                half3 col = diffuseColor.xyz * mainLight.color * NdotL;


                return half4(col, 1.0); 
            }
            ENDHLSL
        }
    }
}
