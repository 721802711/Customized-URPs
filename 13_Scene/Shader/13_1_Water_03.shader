Shader "URP/URP_Water_01"
{
    Properties
    {
        // 水面颜色
        _DeepColor ("DeepColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShallowColor ("shallowColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DepthFadeDistance("Depth Fade Distance",Range(0,5)) = 0.005
        [Space(30)]
        // 地平线颜色
        _HorizonColor ("Horizon Color", Color) = (1.0,1.0,1.0,1.0)
        _HorizonDistance ("Horizon Distance", Range(0,40)) = 20
        [Space(30)]
        // 折射
        _RefractionScale("Refraction Scale",Range(0.01,0.5)) = 0.1
        _RefractionSpeed("Refraction Speed",Range(0,1)) = 0.1
        _RefractionStrength("Refraction Strength",Range(0,0.05)) = 0
        [Space(30)]
        _NoiseMap ("_Noise Map", 2D) = "white" {}                        //噪波贴图
        _RefractionSize("_RefractionSize", Vector) = (0,0,0,0)
        _RefractionScale("Refraction Scale",Range(0.01,0.5)) = 0.1
        _SceneMoveDepth("_SceneMoveDepth",float) = 1.0                            //折射噪音影响深度效果
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"   
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"  
        #include "HSVLerp.hlsl"
 
        CBUFFER_START(UnityPerMaterial)
        float _DepthFadeDistance, _HorizonDistance, _RefractionScale;
        float4 _DeepColor,_ShallowColor, _HorizonColor;
        float4 _RefractionSize;
        float _SceneMoveDepth;
        CBUFFER_END

        TEXTURE2D(_NoiseMap);                          SAMPLER(sampler_NoiseMap);

        TEXTURE2D(_CameraDepthTexture);                            
        SAMPLER(sampler_CameraDepthTexture);                       //获取深度贴图     
       

        // 顶点着色器的输入
        struct a2v
        {
            float3 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord :TEXCOORD0; 
        };
        
        // 顶点着色器的输出
        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL;
            float3 positionWS: TEXCOORD1;
            float3 tangentWS : TEXCOORD2;
            float3 bitangentWS : TEXCOORD3;
            float3 ViewDirectionWS : TEXCOORD4;
        };
        ENDHLSL

        Pass
        {
            Name "Pass"
            Tags 
            { 
                "LightMode" = "UniversalForward"
                "RenderType"="Transparent"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha

 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            /*
             那么屏幕坐标的计算方法 
             screenPosX = ((x / w) * 0.5 + 0.5) * width
             screenPosY = ((y / w) * 0.5 + 0.5) * height

             变换后的结果 unity代码类似
             o.x = (pos.x * 0.5 + pos.w * 0.5)
             o.y = (pos.y * 0.5 * _ProjectionParams.x + pos.w * 0.5)
            */
            float4 ComputeScreenPos(float4 pos, float projectionSign)                          //齐次坐标变换到屏幕坐标
            {
                float4 o = pos * 0.5f;
                o.xy = float2(o.x,o.y * projectionSign) + o.w;             
                o.zw = pos.zw;
                return o;
			}

            float CustomSampleSceneDepth(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,uv).r;        
			}

            //输入世界空间   WorldPos   
            float GetDepthFade(float3 WorldPos, float Distance)
            {
                float4 posCS = TransformWorldToHClip(WorldPos);                                            //转换成齐次坐标   
                float4 ScreenPosition = ComputeScreenPos(posCS, _ProjectionParams.x);                      //齐次坐标系下的屏幕坐标值
                //从齐次坐标变换到屏幕坐标， x,y的分量 范围在[-w,w]的范围   _ProjectionParams 用于在使用翻转投影矩阵时（此时其值为-1.0）翻转y的坐标值。
                //这里
                float screenDepth = CustomSampleSceneDepth(ScreenPosition.xy / ScreenPosition.w);        //计算屏幕深度 是非线性
     
                float EyeDepth = LinearEyeDepth(screenDepth,_ZBufferParams);                            //深度纹理的采样结果转换到视角空间下的深度值
                return saturate((EyeDepth - ScreenPosition.w)/ Distance);                               //使用视角空间下所有深度 减去模型顶点的深度值
			}


            //UV动画
            float2 UVMovement(float2 uv,half U,half V, float scale)
            {
		        float2 newUV = uv * scale + (_Time.y * (half2(U,V)));
		        return newUV;
            }

            float3 GetSceneColor(float3 WorldPos,float2 uv_move)
            {
                    float4 ScreenPosition = ComputeScreenPos(TransformWorldToHClip(WorldPos), _ProjectionParams.x);  
                    return SampleSceneColor((ScreenPosition.xy + uv_move) / ScreenPosition.w);
            }


            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS    = NormalInputs.tangentWS;
                o.bitangentWS  = NormalInputs.bitangentWS;

                o.ViewDirectionWS = GetWorldSpaceNormalizeViewDir(o.positionWS);
                o.uv = v.texcoord;
                return o;
            }
 
            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {    
                
                Light mylight = GetMainLight();                                //获取场景主光源

                float3 WorldSpaceNormal = normalize(i.normalWS);


                // 深度
                float depthfade = GetDepthFade(i.positionWS, _DepthFadeDistance);

                // 颜色
                float4 watercolor;
                HSVLerp_float(_DeepColor, _ShallowColor, depthfade, watercolor);

                // 地平线颜色
                float freshe;
                FresnelEffect(WorldSpaceNormal, i.ViewDirectionWS, _HorizonDistance, freshe);
                float4 horizonCor = lerp(watercolor, _HorizonColor, freshe);


                // 折射
                
                float2 ReflactionMoveUV = UVMovement(i.uv, _RefractionSize.x,_RefractionSize.y,_RefractionScale);
                float ReflactionNoise = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,ReflactionMoveUV);
                float ReflactionSceneMoveDepth = saturate(GetDepthFade(i.positionWS, _SceneMoveDepth));

                float3 SceneColor = GetSceneColor(i.positionWS,float2(ReflactionNoise * _RefractionSize.z,ReflactionNoise * _RefractionSize.w) * ReflactionSceneMoveDepth);


                float4 col = float4(0,0,0,0);   
             
                col.rgb = SceneColor;
                //col.a = watercolor.a;

                return col;
            }        
            ENDHLSL
        }
    }
}