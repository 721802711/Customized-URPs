Shader "B/TS_ScreenOccupancyRange"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}
        _HeightScale ("_HeightScale", Range(0.01,1)) = 0

        [KeywordEnum(integer, fractional_even, fractional_odd )]_Partitioning ("Partitioning Mode", Float) = 2
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1, 8)) = 4 
        _PhoneShape ("PhoneShape", Range(0, 1)) = 0.5

        _TriangleSize ("TriangleSize", Range(0, 200)) = 10
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
        float _TriangleSize;
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
            float3 normalWS : TANGENT;
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
            float3 normalWS : TANGENT; // 传递法线信息
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
            real3 GetScreenSpaceTessFactor(real3 p0, real3 p1, real3 p2, real4x4 viewProjectionMatrix, real4 screenSize, real triangleSize)
            {
                // Get screen space adaptive scale factor
                real2 edgeScreenPosition0 = ComputeNormalizedDeviceCoordinates(p0, viewProjectionMatrix) * screenSize.xy;
                real2 edgeScreenPosition1 = ComputeNormalizedDeviceCoordinates(p1, viewProjectionMatrix) * screenSize.xy;
                real2 edgeScreenPosition2 = ComputeNormalizedDeviceCoordinates(p2, viewProjectionMatrix) * screenSize.xy;

                real EdgeScale = 1.0 / triangleSize; // Edge size in reality, but name is simpler
                real3 tessFactor;
                tessFactor.x = saturate(distance(edgeScreenPosition1, edgeScreenPosition2) * EdgeScale);
                tessFactor.y = saturate(distance(edgeScreenPosition0, edgeScreenPosition2) * EdgeScale);
                tessFactor.z = saturate(distance(edgeScreenPosition0, edgeScreenPosition1) * EdgeScale);

                return tessFactor;
            }
            real4 CalcTriTessFactorsFromEdgeTessFactors(real3 triVertexFactors)
            {
                real4 tess;
                tess.x = triVertexFactors.x;
                tess.y = triVertexFactors.y;
                tess.z = triVertexFactors.z;
                tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0;

                return tess;
            }

            //  曲面着色器常量函数
            PatchTess PatchConstant(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
            {
                PatchTess o;

                real3 triVectexFactors =  GetScreenSpaceTessFactor(patch[0].positionWS, patch[1].positionWS, patch[2].positionWS, GetWorldToHClipMatrix() , _ScreenParams, _TriangleSize);
                float4 tessFactors = _EdgeFactor * CalcTriTessFactorsFromEdgeTessFactors(triVectexFactors); // 计算细分因子
                o.edgeFactor[0] = max(1.0, tessFactors.x); // 边缘细分因子
                o.edgeFactor[1] = max(1.0, tessFactors.y);
                o.edgeFactor[2] = max(1.0, tessFactors.z);

                o.insideFactor = max(1.0, tessFactors.w); // 内部细分因子

                return o;
            }
            
            //  ==========================================================================================================================================
            float3 ProjectPointOnPlane(float3 position, float3 planePosition, float3 planeNormal)
            {
                return position - (dot(position - planePosition, planeNormal) * planeNormal);
            }

            real3 PhongTessellation(real3 positionWS, real3 p0, real3 p1, real3 p2, real3 n0, real3 n1, real3 n2, real3 baryCoords, real shape)
            {
                // 分别计算三个切平面的投影点
                real3 c0 = ProjectPointOnPlane(positionWS, p0, n0);
                real3 c1 = ProjectPointOnPlane(positionWS, p1, n1);
                real3 c2 = ProjectPointOnPlane(positionWS, p2, n2);

                // 利用质心坐标插值得到最终顶点位置
                real3 phongPositionWS = baryCoords.x * c0 + baryCoords.y * c1 + baryCoords.z * c2;

                // 通过shape 控制平滑程度
                return lerp(positionWS, phongPositionWS, shape);
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
            HullOut PhoneTriControlPoint (InputPatch<VertexOut, 3> patch, uint id : SV_OutputControlPointID)
            {
                HullOut o;

                o.positionWS = patch[id].positionWS;
                o.texcoord   = patch[id].texcoord;
                o.normalWS   = patch[id].normalWS; // 传递法线

                return o;

            }

            // 域着色器
            [domain("tri")]   // 
            v2f PhoneTriTessDomain (PatchTess tessFactors, const OutputPatch<HullOut, 3> patch, float3 bary : SV_DOMAINLOCATION)
            {
                // u, v, w 代表 重心坐标
                float u = bary.x;
                float v = bary.y;
                float w = bary.z;
                // 插值法线
                float3 interpolatedNormal = patch[0].normalWS * u +  patch[1].normalWS * v +  patch[2].normalWS * w;
                // uv
                float2 texcoord   = patch[0].texcoord * u + patch[1].texcoord * v + patch[2].texcoord * w;
                // 采样高度图
                float height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, texcoord, 1.0).r; // 假设高度值存储在红色通道
                height =  height * _HeightScale - _HeightScale / 2.0;


                // 计算顶点
                // 这里使用Tessellation库的 PhongTessellation 函数
                float3 positionWS = patch[0].positionWS * u + patch[1].positionWS * v + patch[2].positionWS * w; 
                positionWS.xyz += interpolatedNormal * height;
                positionWS = PhongTessellation(positionWS, patch[0].positionWS, patch[1].positionWS, patch[2].positionWS, patch[0].normalWS, patch[1].normalWS, patch[2].normalWS, bary, _PhoneShape);



                v2f output;

                output.positionCS = TransformWorldToHClip(positionWS);    // 世界坐标转换到裁剪空间
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


                return half4(col.rgb, 1.0); 
            }
            ENDHLSL
        }
    }
}
