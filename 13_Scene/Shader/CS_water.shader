Shader "URP/CS_water"
{
    Properties
    {
        // 水面颜色
        _DepthFadeDistance("Depth Fade Distance",Range(0,20)) = 0.005
        _ShallowColor ("shallowColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DeepColor ("DeepColor", Color) = (1.0, 1.0, 1.0, 1.0)

        [Space(30)]
        _HorizonColor ("HorizonColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _HorizonDistance ("HorizonDistance", Range(0, 10)) = 5
        [Space(30)]
        // 折射
        _RefractionStrength ("RefractionStrength", Range(0, 0.05)) = 0
        _RefractionScale ("RefractionScale", Range(0.01, 1)) = 0.1
        _RefractionSpeed ("RefractionSpeed", Range(0, 1)) = 0.1

        // 水花
        [Space(30)]
        _SurfaceFoamTex ("Surface Foam Texture", 2D) = "white" {}              // 水花纹理
        _SurfaceFoamTiling ("Surface Foam Tiling", Range(0, 100)) = 1           // 水花缩放
        _SurfaceFoamDirection ("Surface Foam Direction", Range(0, 1)) = 0      // 水花方向
        _SurfaceFoamSpeed ("Surface Foam Speed", Range(0, 1)) = 0.5            // 水花速度
        _SurfaceFoamColor ("Surface Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SurfaceFoamColorBlend ("_SurfaceFoamColorBlend", Range(0, 1)) = 0
        _SurfaceFoamDistortion ("Surface Foam Distortion", Range(0, 10)) = 0.5  // 水花扭曲

        // 边缘
        [Space(30)]
        _IntersectionFoamColor ("IntersectionFoamColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _IntersectionFoamColorBlend ("IntersectionFoamColorBlend", Range(0, 1)) = 0
        _IntersectionFoamFade ("intersectionFoamFade", Range(0, 1)) = 0.5
        _IntersectionFoamDepth ("IntersectionFoamDepth", Range(0, 5)) = 5


        _IntersectionDistortion ("IntersectionDistortion", Range(0, 10)) = 0.5

        [Space(20)]
        _NoiseMap ("NoiseMap", 2D) = "white" {}
        _NoiseFoamTiling ("Noise Foam Tiling", Range(0, 100)) = 1           // 噪声图缩放
        _NoiseMapFoamDirection ("NoiseMap Foam Direction", Range(0, 1)) = 0  // 噪声图方向
        _NoiseMapFoamSpeed ("NoiseMap Foam Speed", Range(0, 1)) = 0.5        // 噪声图速度
        [Space(20)]
        _IntersectionFoamCutoff ("IntersectionFoamCutoff", Range(0, 1)) = 0.5

        // 顶点动画
        [Space(30)]
        _WaveSteepness ("Wave Steepness", Range(0, 1)) = 0
        _WaveLength ("Wave Length", Range(1, 10)) = 1
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 0.1
        _WaveDirections ("Wave Directions", Vector) = (0, 0.5, 1, 0.2)
        // 纹理贴图
        _WaterMap ("WiterMap", 2D) = "white" {}
        _WaterSpeed ("Water Speed", Vector) = (1.0, 1.0, 0.1, 0.1)
        _WaterStrength ("Water Strength", Range(0, 2)) = 0.1


        // 法线贴图
        [Space(30)]
        _NormalsTex ("NormalsTex", 2D) = "bump" {}
        _NormalsStrength ("Normals Strength", Range(0, 3)) = 0.5
        _NormalsSpeed ("Normals Speed", Range(0, 0.2)) = 0.1
        _NormalsScale ("Normals Scale", Range(0, 0.2)) = 0.1

        [Space(30)]
        // Light
        _smoothness ("Smoothness", Range(0, 1)) = 0.5
        _hardness ("Hardness", Range(0, 1)) = 0.5
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        #include "DepthFade.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _NormalsTex_ST;
        float4 _DeepColor,_ShallowColor, _HorizonColor, _IntersectionFoamColor,_SurfaceFoamColor, _SpecularColor;
        float _DepthFadeDistance, _HorizonDistance, _IntersectionFoamFade, _IntersectionFoamDepth, _IntersectionFoamCutoff;
        float _NoiseFoamTiling, _NoiseMapFoamDirection, _NoiseMapFoamSpeed, _RefractionScale, _RefractionSpeed, _RefractionStrength;
        float _SurfaceFoamTiling, _SurfaceFoamDirection, _SurfaceFoamSpeed, _SurfaceFoamDistortion, _IntersectionDistortion;
        float _SurfaceFoamColorBlend, _IntersectionFoamColorBlend, _WaveSteepness, _WaveLength, _WaveSpeed, _WaterStrength;
        float4 _WaveDirections, _WaterSpeed;
        float _NormalsScale, _NormalsSpeed, _NormalsStrength;
        float _smoothness, _hardness;
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
            


            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                //前计算噪波贴图 的uv
                float2 offUV = float2(v.texcoord.x * _WaterSpeed.x, v.texcoord.y * _WaterSpeed.y);

                float3 posWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 abcWSpos = GetAbsolutePositionWS(posWS);   // 获取绝世界空间位置

                //前计算噪波贴图 的uv
                float2 NoiseUV = float2(offUV.x  + (_WaterSpeed.z * _Time.y), offUV.y  + (_WaterSpeed.w * _Time.y));                   //噪波贴图uv
                float noise = (SAMPLE_TEXTURE2D_LOD(_WaterMap, sampler_WaterMap,NoiseUV,1.0).r - 0.5f);


                float3 offset = float3(0,0,0);
                float3 normal = float3(0,0,0);

                // 波浪
                GerstnerWave(abcWSpos, _WaveSteepness, _WaveLength, _WaveSpeed, _WaveDirections, offset, normal);
                abcWSpos += offset + noise * _WaterStrength;

                float3 WaterPos = TransformWorldToObject(abcWSpos);  // 获取水面位置
                v.positionOS.z += WaterPos.z;                           

                // 顶点动画
                o.uv = v.texcoord;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = posWS;                                              //获取世界空间位置信息


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
                

                float2 NDCPosition = (i.positionCS.xy / _ScreenParams.xy);
                float2 UV = float2(2,2);
                
                // 折射UV
                float2 OffsetUV = TilingAndOffset(i.uv, rcp(_RefractionScale), _Time.y * _RefractionSpeed);
                float refractionTex = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,OffsetUV);
                // 映射到 [-1, 1]
                refractionTex = Remap(refractionTex, float2(0,1), float2(-1,1)) * _RefractionStrength;

                // 纹理
                float4 cheep = refractionTex + half4(NDCPosition.xy, 0, 0);
                
                // 世界空间位置
                float3 scePos = ScenePosition(cheep.xy, i.positionWS, i.screenPos);
                float3 posWS = i.positionWS - scePos;
                float  compA = Comparison(posWS.g, 0);
                // 
                float2 expensive = Branch(compA, cheep, half4(NDCPosition, 0, 0));


                // 深度衰减
                float ExponentialFade;
                float LinearFade;
                ComputeDepthFade(expensive, _DepthFadeDistance, i.positionWS, i.screenPos, ExponentialFade, LinearFade);

                // 水面颜色
                float4 DepthCol = lerp(_DeepColor, _ShallowColor, ExponentialFade);

                // 远距离颜色
                float fresnel = Fresnel(i.normalWS, i.viewDirectionWS, _HorizonDistance);
                float4 horizonCol = lerp(DepthCol, _HorizonColor, fresnel);

                // 场景颜色
                half3 ScrCol = ScreenColor(i.positionCS, expensive);
                half4 underwatercol =  (1 - horizonCol.a) * half4(ScrCol.rgb,0);
                underwatercol += horizonCol;

                // 边缘范围
                float exgeExponentialFade;
                float edgeLinearFade;

                ComputeDepthFade(NDCPosition, _IntersectionFoamDepth, i.positionWS, i.screenPos, exgeExponentialFade, edgeLinearFade);
                float edgecol = 1 - smoothstep((1 - _IntersectionFoamFade), 1, (edgeLinearFade + 0.1));

                // 边缘水花
                float2 noiseUV = PanningUV(i.uv,_NoiseFoamTiling, _NoiseMapFoamDirection, _NoiseMapFoamSpeed, float2(0,0));
                noiseUV = DistortUV(noiseUV, _IntersectionDistortion);
                float noiseTex = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,noiseUV).r;

                float4 foam = saturate(step((edgeLinearFade * _IntersectionFoamCutoff), noiseTex));
                foam.rgb *= _IntersectionFoamColor.rgb; 
                foam.a *=  edgecol;

                // 水花
                float2 surfaceUV = PanningUV(i.uv,_SurfaceFoamTiling, _SurfaceFoamDirection, _SurfaceFoamSpeed, float2(0,0));
                surfaceUV = DistortUV(surfaceUV, _SurfaceFoamDistortion);
                float surfaceTex = SAMPLE_TEXTURE2D(_SurfaceFoamTex,sampler_SurfaceFoamTex,surfaceUV).r;
                float4 surfaceCol = step(0.5, surfaceTex) * _SurfaceFoamColor;

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

                // ==========================================================================================================
                // 计算光照

                float3 positionWS = normalize(i.positionWS);
                float3 viewDirectionWS = normalize(i.viewDirectionWS);

                // 计算光照
                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = float4(mylight.color,1);                     //获取主光源的颜色
                half3 LightDir = normalize(mylight.direction);                 //获取光照方向


                // 计算主光源高光
                float mainColor = MainLighting(normalWS, positionWS, viewDirectionWS, _smoothness);
                mainColor = lerp(step(0.5, mainColor), mainColor, _hardness);

                // 设置高光颜色
                float4 specular = mainColor * _SpecularColor;
                specular *= _SpecularColor.a;

                // 计算多光源高光
                float3 addColor = AdditionalLighting(normalWS, positionWS, viewDirectionWS, _smoothness, _hardness);                


                // ==========================================================================================================

                // 汇总
                float4 basicCol = Overlay(underwatercol, foam, _IntersectionFoamColorBlend);    // 基础颜色
                float3 waterSplash = Overlay(basicCol, surfaceCol, _SurfaceFoamColorBlend);   // 水花
                float3 waterSpecular = specular + addColor;                                  // 高光
                // ===========================================================================================================


                half4 col = half4(0,0,0,0);


                col.rgb = waterSpecular + waterSplash;
                col.a = 1;

                return col;
            }        
            ENDHLSL
        }
    }
}