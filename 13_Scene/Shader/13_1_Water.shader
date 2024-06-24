Shader "B/13_1_Water"
{
    Properties
    {
        _ShallowWater ("shallowColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DeepWater ("DeepColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DepthDdgeSize("_DepthDdgeSize",Range(0,100)) = 0.005

        [Space(30)]
        _NoiseMap ("_Noise Map", 2D) = "white" {}                        //噪波贴图
        _WaterSpeed("_WaterSpeed", Vector) = (0,0,0,0)                                    //水面移动速度
        _SceneMoveDepth("_SceneMoveDepth",float) = 1.0                            //折射噪音影响深度效果
        _WaterStrength("_WaterStrength",Range(0,0.5)) = 0.1      
        
        [Space(30)]

        _RefractionSize("_RefractionS", Vector) = (0,0,0,0)
        _RefractionScale("_RefractionScale",float) = 1.0


        [Space(30)]
        _FoamSize ("_FoamSize", Vector) = (0,0,0,0)
        _FoamScale("_FoamScale",float) = 1.0
        _FoamColor("_FoamColor",Color) = (1.0,1.0,1.0,1.0)
        _FoamAmount("_FoamAmount",float) = 1.0 
        _FoamCutoff("_FoamCutoff",float) = 1.0 
        _FoamAlpha("_FoamAlpha",float) = 1.0 
        _ReflectBlur("反射模糊", Range( 0 , 1)) = 0

        [Space(30)]
        [Normal]_NormalMap ("_Normal Map", 2D) = "bump"{}
        _NormalScale("_NormalScale",float) = 1.0


        [Space(30)]
        _Metallic ("Metallic", Range (0,1)) = 0.0
        _Roughness ("Roughness", Range (0,1)) = 0.5

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST,_NoiseMap_ST;
        float _DepthDdgeSize, _SceneMoveDepth, _WaterStrength, _Metallic, _Roughness;
        float4 _WaterSpeed, _RefractionSize, _FoamColor;
        float4 _ShallowWater,_DeepWater, _FoamSize;
        float _RefractionScale, _FoamSpeed_U,_FoamSpeed_V, _FoamScale, _FoamAmount, _FoamCutoff, _FoamAlpha, _NormalScale, _ReflectBlur;
        CBUFFER_END

        struct appdata
        {
            float3 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord :TEXCOORD0; 
        };

        struct v2f
        {
            float4 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 positionWS:TEXCOORD1;
            float3 normalWS : NORMAL;
            float3 tangentWS : TANGENT;
            float3 bitangentWS : TEXCOORD2;
        };

        //TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseMap);                          SAMPLER(sampler_NoiseMap);
        TEXTURE2D(_NormalMap);                          SAMPLER(sampler_NormalMap);
        TEXTURE2D(_CameraDepthTexture);                            
        SAMPLER(sampler_CameraDepthTexture);                       //获取深度贴图  

        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag



            float4 ComputeScreenPos(float4 pos, float projectionSign)                          //齐次坐标变换到屏幕坐标
            {
                float4 o = pos * 0.5f;
                o.xy = float2(o.x,o.y * projectionSign) + o.w;             
                o.zw = pos.zw;
                return o;
			}

            float CustomSampleSceneDepth(float2 uv)
            {
                return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;           
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


            float3 GetSceneColor(float3 WorldPos,float2 uv_move)
            {
                    float4 ScreenPosition = ComputeScreenPos(TransformWorldToHClip(WorldPos), _ProjectionParams.x);  
                    return SampleSceneColor((ScreenPosition.xy + uv_move) / ScreenPosition.w);
            }


            //UV动画
            float2 UVMovement(float2 uv,half U,half V, float scale)
            {
		        float2 newUV = uv * scale + (_Time.y * (half2(U,V)));
		        return newUV;
            }



            float DistributionGGX(float NoH, float a)
            {
                float a2 = a * a;
                float NoH2 = NoH * NoH;

                float nom = a2;
                float denom = NoH2 * (a2 - 1) + 1;
                denom = denom * denom * PI;
                return nom / denom;
            }

            float GeometrySchlickGGX(float NoV, float k)
            {
                float nom = NoV;
                float denom = NoV * (1.0 - k) + k;
                return nom / denom;
            }

            float GeometrySmith(float NoV, float NoL, float k)
            {
                float ggx1 = GeometrySchlickGGX(NoV, k);
                float ggx2 = GeometrySchlickGGX(NoL, k);
                return ggx1 * ggx2;
            }

            float3 FresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + pow(1.0 - cosTheta, 5.0);
            }




            v2f vert (appdata v)
            {
                v2f o;

                //前计算噪波贴图 的uv
                float2 offUV = float2(v.texcoord.x * _WaterSpeed.x, v.texcoord.y * _WaterSpeed.y);


                float3 posWS = TransformObjectToWorld(v.positionOS.xyz);
                float ReflactionSceneMoveDepth = GetDepthFade(posWS, _SceneMoveDepth);    
                float posDepth = saturate(ReflactionSceneMoveDepth);


                //前计算噪波贴图 的uv
                float2 NoiseUV = float2(offUV.x  + (_WaterSpeed.z * _Time.y), offUV.y  + (_WaterSpeed.w * _Time.y));                   //噪波贴图uv
                float noise = (SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap,NoiseUV,1.0).r - 0.5f) * posDepth;
                v.positionOS.z += noise * _WaterStrength;    //输出到顶点坐标.y


                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;


                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS    = NormalInputs.tangentWS;
                o.bitangentWS  = NormalInputs.bitangentWS;


                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseMap);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                
                // 颜色
                float depthfade = GetDepthFade(i.positionWS.xyz, _DepthDdgeSize);     // 计算深度
                float4 watercolor = lerp(_DeepWater,_ShallowWater,depthfade);


                //扭曲水
                float2 ReflactionMoveUV = UVMovement(i.uv, _RefractionSize.x,_RefractionSize.y,_RefractionScale);
                float ReflactionNoise = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,ReflactionMoveUV);

                float ReflactionSceneMoveDepth = saturate(GetDepthFade(i.positionWS, _SceneMoveDepth));
                float3 SceneColor = GetSceneColor(i.positionWS,float2(ReflactionNoise * _RefractionSize.z,ReflactionNoise * _RefractionSize.w) * ReflactionSceneMoveDepth);


                //边缘
                float2 FilterMoveUV = UVMovement(i.uv.zw,_FoamSize.x,_FoamSize.y,_FoamScale);
                float FilterNoise = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,FilterMoveUV).r;
                float filterSceneMoveDepth = GetDepthFade(i.positionWS, _FoamAmount) * _FoamCutoff;
                float WaterFilter = step(filterSceneMoveDepth,FilterNoise) * _FoamAlpha;



                float4 NormaldataTex = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv);
                float3 Normaldata  = UnpackNormal(NormaldataTex);

                Light mylight = GetMainLight();                                //获取场景主光源
                float4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色

                // ==================================
                float3 worldpos = i.positionWS;
                float3 V = normalize(GetCameraPositionWS().xyz-i.positionWS);
                float3 N = normalize(Normaldata.x * i.tangentWS * _NormalScale + Normaldata.y * i.bitangentWS * _NormalScale + i.normalWS);
                float3 R = reflect(-V,N);                     // 计算出反射向量  
                float3 L = mylight.direction;
                float3 H = normalize(V + L);


                float3 CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, _ReflectBlur * 6);   // 使用反射控制Cube等级

                float3 F0 = lerp(0.04,CubeMapColor,_Metallic);

                float NdotV = max(saturate(dot(N, V)), 0.000001);
                float NdotL = max(saturate(dot(N, L)), 0.000001);
                float HdotV = max(saturate(dot(H, V)), 0.000001);
                float NdotH = max(saturate(dot(H, N)), 0.000001);
                float LdotH = max(saturate(dot(H, L)), 0.000001);

                // ==================================

                float D = DistributionGGX(NdotH,_Roughness);
                float K = pow(1 + _Roughness,2)/8;
                float G = GeometrySmith(NdotV,NdotL,K);
                float F = FresnelSchlick(LdotH,F0);               //这里需要F0



                float3 specular = D * G * F/(4 * NdotV * NdotL);
                                
                float3 ks = F;
                float3 kd = (1-ks) * (1 - _Metallic);
                float3 diffuse = kd * CubeMapColor / PI;
                float3 DirectColor = (diffuse + specular) * NdotL * PI * mylight.color;


                float4 final_color = lerp(watercolor,_FoamColor,WaterFilter);   // 水面颜色

                float4 col;

                col.rgb = lerp(SceneColor,final_color.rgb,final_color.a) + DirectColor;;
                col.a = 1;

                return col;
            }
            ENDHLSL
        }
    }
}