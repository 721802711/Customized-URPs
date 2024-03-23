Shader "B/02_DisplacementMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}
        _HeightScale ("InsideFactor", Range(0.01,1)) = 1
        _Gloss ("Gloss", Range(32, 256)) = 64
        [KeywordEnum(integer, fractional_even, fractional_odd)]_Partitioning ("Partitioning Mode", Float) = 0
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1,8)) = 4 
        _InsideFactor ("InsideFactor", Range(1,8)) = 4 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE


        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _HeightMap_ST;
        float _EdgeFactor, _Gloss; 
        float _InsideFactor; 
        float _HeightScale;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
            };

            // 第一个
            struct VertexOut 
            {
                float3 positionOS : INTERNALTESSPOS;     // 用于细分的内部顶点位置
                float2 texcoord : TEXCOORD0;
                float4 normal : NORMAL;
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
                float4 normal : NORMAL; // 传递法线信息
            };


            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 normal : NORMAL;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM

            #pragma target 4.6 

            #pragma vertex vert                         // 顶点着色器
            #pragma hull FlatTessControlPoint           // 曲面着色器
            #pragma domain FlatTessDomain               // 域着色器
            #pragma fragment frag                       // 片段着色器

            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD 
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 

            //  ==========================================================================================================================================


            // 模型顶点传入到 VertexOut结构体
            VertexOut vert(appdata v)           
            {
                VertexOut o;
                o.positionOS = v.positionOS;
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex); 
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



            // 设置细分属性

            [domain("tri")] // 域类型：三角形

            #if _PARTITIONING_INTEGER
            [partitioning("integer")] // 划分模式：整数
            #elif _PARTITIONING_FRACTIONAL_EVEN
            [partitioning("fractional_even")] // 划分模式：偶数分数
            #elif _PARTITIONING_FRACTIONAL_ODD
            [partitioning("fractional_odd")] // 划分模式：奇数分数
            #endif

            #if _OUTPUTTOPOLOGY_TRIANGLE_CW
            [outputtopology("triangle_cw")] // 输出拓扑：顺时针三角形
            #elif _OUTPUTTOPOLOGY_TRIANGLE_CCW
            [outputtopology("triangle_ccw")] // 输出拓扑：逆时针三角形
            #endif

            [patchconstantfunc("PatchConstant")] // 细分常量函数：PatchConstant
            [outputcontrolpoints(3)] // 输出控制点数量：3
            [maxtessfactor(64.0f)] // 最大细分因子：64.0


            //  ==========================================================================================================================================
            // 曲面着色器阶段
            HullOut FlatTessControlPoint (InputPatch<VertexOut, 3> patch, uint id : SV_OutputControlPointID)
            {
                HullOut o;

                o.positionOS = patch[id].positionOS;
                o.texcoord = patch[id].texcoord;
                o.normal = patch[id].normal; // 传递法线
                return o;

            }

            // 域着色器
            [domain("tri")]   // 
            v2f FlatTessDomain(PatchTess tessFactors, const OutputPatch<HullOut, 3> patch, float3 bary : SV_DOMAINLOCATION)
            {


                // 插值法线
                float4 interpolatedNormal = bary.x * patch[0].normal + bary.y * patch[1].normal + bary.z * patch[2].normal;

                // 计算新的顶点位置
                float3 positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z; 
                float2 texcoord   = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;

                // 采样高度图
                float height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, texcoord * _HeightMap_ST.xy + _HeightMap_ST.zw, 1.0).r  * _HeightScale; // 假设高度值存储在红色通道
                // 顶点应用法线方向和高度图
                positionOS.xyz += interpolatedNormal * height;


                v2f output;

                output.positionCS = TransformObjectToHClip(positionOS);    // 世界坐标转换到裁剪空间
                output.uv = texcoord;                                 // 纹理坐标
                output.normal = interpolatedNormal; // 输出插值的法线
                return output;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);


                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = float4(mylight.color,1);                     //获取主光源的颜色
                half3 LightDir = normalize(mylight.direction);                 //获取光照方向


                float4 normalTS = i.normal;
                float LdotN = dot(LightDir,normalTS) * 0.5 + 0.5;                      //LdotN    这里使用新的法线信息。



                half3 diffuseColor = LightColor * albedo.rgb * LdotN;         // 应用 高度转法线效果


                half4 col = half4(diffuseColor, 1); 

                return col;
            }
            ENDHLSL
        }
    }
}
