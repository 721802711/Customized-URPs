Shader "URP/14_NormalBlend"
{
    Properties
    {
        // 法线贴图
        [Space(30)]
        _NormalsTex ("NormalsTex", 2D) = "bump" {}
        _NormalsStrength ("Normals Strength", Range(0, 3)) = 0.5
        _NormalsSpeed ("Normals Speed", Range(0, 0.2)) = 0.1
        _NormalsScale ("Normals Scale", Range(0, 0.2)) = 0.1
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  


        CBUFFER_START(UnityPerMaterial)
        float4 _NormalsTex_ST;
        float _NormalsStrength;
        float _NormalsSpeed;
        float _NormalsScale;
        CBUFFER_END


        TEXTURE2D(_NoiseMap);                          SAMPLER(sampler_NoiseMap);
        TEXTURE2D(_WaterMap);                          SAMPLER(sampler_WaterMap);
        TEXTURE2D(_NormalsTex);                        SAMPLER(sampler_NormalsTex);
        TEXTURE2D(_SurfaceFoamTex);                    SAMPLER(sampler_SurfaceFoamTex);
       
        // 顶点着色器的输入
        struct a2v
        {
            float4 positionOS : POSITION; // 物体空间顶点位置
            float3 normalOS : NORMAL;     // 物体空间法线
            float2 texcoord : TEXCOORD0;  // 纹理坐标
            float4 tangentOS : TANGENT;   // 物体空间切线
        };
        
        // 顶点着色器的输出
        struct v2f
        {
            float4 positionCS : SV_POSITION;  // 裁剪空间位置
            float3 positionWS : TEXCOORD0;    // 世界空间位置
            float3 normalWS : TEXCOORD1;      // 世界空间法线
            float3 tangentWS : TEXCOORD2;     // 世界空间切线
            float3 bitangentWS : TEXCOORD3;   // 世界空间副切线
            float3 viewDirectionWS : TEXCOORD4; // 世界空间视角方向
            float2 uv : TEXCOORD5;            // 纹理坐标
            float4 screenPos : TEXCOORD6;     // 屏幕坐标位置

        };

        ENDHLSL

        Pass
        {
            Name "Pass"
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }

            //Blend SrcAlpha OneMinusSrcAlpha

 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            float2 PanningUV(float2 uv, float Tiling, float direction, float speed, float2 Offset)                 //UV平移
            {
                float2 TiledUV = uv * Tiling;

                //  Direction 转换为弧度并计算其余弦和正弦值
                float Radians = (direction * 2 - 1) * 3.141593;
                float Cosine = cos(Radians);
                float Sine = sin(Radians);

                float2 DirectionVector = normalize(float2(Cosine, Sine));
                // 计算速度乘以时间
                float ScaledTime = _Time.y * speed;
                // 计算平移量
                float2 Translation = DirectionVector * ScaledTime;
                // 输出 UV 加上平移量和 Offset
                return TiledUV + Translation + Offset;
            }

            float3 NormalBlend(float3 A, float3 B)
            {
                return SafeNormalize(float3(A.rg + B.rg, A.b * B.b));
            }


            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                // 顶点动画
                o.uv = v.texcoord;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                                              //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;

                o.viewDirectionWS = GetWorldSpaceNormalizeViewDir(o.positionWS);    // 世界空间视角方向

                o.screenPos = ComputeScreenPos(o.positionCS);                      // 计算屏幕坐标
                return o;
            }
 
            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {    
                
                // ===========================================================================================================
                // 法线贴图
                // 缩放因子
                float scale = _NormalsScale;
                float scaledHalf = 0.5 * scale;
                float reciprocalScale = 1.0 / scaledHalf;
                float speed = -0.5 * _NormalsSpeed;

                // 计算Panning UV
                float2 PanningUV1 = PanningUV(i.uv, reciprocalScale, 1.0, speed, float2(0.0, 0.0));

                // 采样第二个法线纹理
                float2 PanningUV2 = PanningUV(i.uv, 1.0 /_NormalsScale, 1.0, _NormalsSpeed, float2(0.0, 0.0));
            
                float4 normalTex1 = SAMPLE_TEXTURE2D(_NormalsTex, sampler_NormalsTex, PanningUV1);
                float4 normalTex2 = SAMPLE_TEXTURE2D(_NormalsTex, sampler_NormalsTex, PanningUV2);
                half3 normalTS1 = UnpackNormalScale(normalTex1, _NormalsStrength);   
                half3 normalTS2 = UnpackNormalScale(normalTex2, _NormalsStrength);

                // 法线贴图混合
                half3 normalTS = NormalBlend(normalTS1.rgb, normalTS2.rgb);

                float3x3 TBN = {i.tangentWS.xyz,i.bitangentWS.xyz,i.normalWS.xyz};          //世界空间法线方向

                float3 normalWS = mul(normalTS,TBN);                                          //顶点法线，和法线贴图融合 == 世界空间的法线信息  

                // ===========================================================================================================


                half4 col = half4(0,0,0,0);


                col.rgb = normalTS;
                col.a = 1;

                return col;
            }        
            ENDHLSL
        }
    }
}