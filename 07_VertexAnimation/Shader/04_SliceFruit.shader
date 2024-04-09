Shader "B/04_SliceFruit"
{
    // 属性定义开始
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} // 定义主纹理
        _Edge ("_Edge" , Range (-0.5, 0.5)) = 0.0 // 边缘值
        [Space(20)]     
        _PlaneTex ("_PlaneTex ", 2D) = "white" {} // 定义平面纹理
        _CircleCol ("Circle Color", Color) = (1, 1, 1, 1) // 圆的颜色
        // edge radius projection
        _CircleRad ("Circle Radius", Range(0.0, 0.5)) = 0.45 // 圆的半径

        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5 // 源混合模式
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10 // 目标混合模式
    } // 属性定义结束
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"} // 标签定义
        Blend[_SrcBlend][_DstBlend] // 混合模式设置

        Cull Off // 剔除背面

        LOD 100 // 细节等级

        HLSLINCLUDE // HLSL代码块开始

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 包含核心库

        CBUFFER_START(UnityPerMaterial) // 材质属性缓冲区开始
        float4 _MainTex_ST;
        float _Edge, _CircleRad;
        float4 _CircleCol;
        CBUFFER_END // 材质属性缓冲区结束

        struct appdata // 顶点输入结构定义
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float4 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
        };

        struct v2f // 顶点输出结构定义
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL; // 输出世界空间下的法线
            float3 hitPos : TEXCOORD1;
        };

        TEXTURE2D(_MainTex); // 主纹理定义
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_PlaneTex); // 平面纹理定义
        SAMPLER(sampler_PlaneTex);

        ENDHLSL // HLSL代码块结束

        Pass // 渲染通道定义
        {
            HLSLPROGRAM // HLSL程序块开始
            #pragma vertex vert // 顶点程序
            #pragma fragment frag // 片段程序


            // SDF 计算 一个点到一个平面的距离
            float planeSDF(float3 ray_position)
            {
                float plane = ray_position.y - _Edge;

                return plane;
            }

            // maximum of steps to determine the surface intersection
            #define MAX_MARCHIG_STEPS 50
            // maximum distance to find the surface intersection
            #define MAX_DISTANCE 10.0
            // surface distance
            #define SURFACE_DISTANCE 0.001

            // 确定光线在空间中传播时与几何体的交互
            float sphereCasting(float3 ray_origin, float3 ray_direction)
            {
                float distance_origin = 0;

                for (int i = 0; i < MAX_MARCHIG_STEPS; i++)
                {
                    float3 ray_position = ray_origin + ray_direction * distance_origin;
                    float distance_scene = planeSDF(ray_position);
                    distance_origin += distance_scene;

                    if (distance_scene < SURFACE_DISTANCE || distance_origin > MAX_DISTANCE)
                        break;
                }

                return distance_origin;
            }


            // 根据_Edge值调整UV坐标的函数
            float2 AdjustUV(float2 uv, float edgeValue)
            {
                // 定义UV缩放的比例因子，可以根据实际需要调整
                float scale = 0.5 + 0.75 * abs(pow(edgeValue * (1 * 0.5), 1)); // 当_Edge为-0.5或0.5时，缩放因子接近0，贴图变得很小
                // 当_Edge为0时，scale接近1.5，贴图显示为最大
                // 根据缩放因子调整UV坐标
                return uv * scale;
            }


            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz); // 获取顶点位置输入
                o.positionCS = PositionInputs.positionCS; // 获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS; // 获取世界空间下法线信息

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // 纹理坐标变换
                o.hitPos = v.positionOS; // 输出顶点位置

                return o;
            }

            half4 frag (v2f i, bool face : SV_isFrontFace) : SV_Target // 片段程序
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv); // 采样主纹理



                // 光线发射点
                float3 ray_origin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 ray_direction = normalize(i.hitPos - ray_origin); // 计算射线方向

                float t = sphereCasting(ray_origin, ray_direction); // 计算交点
                float4 planeCol = 0;
                float4 circleCol = 0;

                if (t < MAX_DISTANCE)
                {
                    float3 p = ray_origin + ray_direction * t;
                    float2 uv_p = p.xz;

                    float l = pow(-abs(_Edge), 2.0) + pow(-abs(_Edge) - 1, 2.0);
                    float c = length(uv_p);


                    // 根据_Edge值调整UV坐标
                    float2 adjustedUV = AdjustUV(uv_p, l);

                    circleCol = (smoothstep(c - 0.01, c + 0.01, _CircleRad - abs(pow(_Edge * (1 * 0.5), 2))));
                    // 计算UV坐标
                    planeCol = SAMPLE_TEXTURE2D(_PlaneTex, sampler_PlaneTex, adjustedUV - 0.5);

                    // 删除纹理边界
                    planeCol *= circleCol;
                    // 添加圆形并应用颜色
                    planeCol += (1 - circleCol) * _CircleCol;

                }

                // 剔除超出边缘的像素
                if (i.hitPos.y > _Edge)
                    discard;

                return face ? col : planeCol; // 根据剔除判断返回颜色
                //return col;
            }
            ENDHLSL // HLSL程序块结束
        }
    }
} // 着色器定义结束