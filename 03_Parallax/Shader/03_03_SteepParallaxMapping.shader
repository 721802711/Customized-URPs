Shader "B/03_03_SteepParallaxMapping"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "bump" { }
        _HeightMap ("_HeightMap", 2D) = "bump"{}       
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(30, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 1)) = 0.1
        _MaxLayerNum ("Max Layer Num", Float) = 50
        _MinLayerNum ("Min Layer Num", Float) = 25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST,_NormalMap_ST, _HeightMap_ST;
        float _HeightScale, _NormalScale,_Gloss;
        float4 _SpecularColor, _DiffuseColor;
        float _MaxLayerNum, _MinLayerNum;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
                float3 tangentWS :TANGENT;                                         //注意 是 float4 类型，W分量储存其他信息
                float3 bitangentWS : TEXCOORD2;                                     //注意 是 float4 类型，W分量储存其他信息
                float3 viewDirWS: TEXCOORD3;                                       //输出视角方向
            };


            TEXTURE2D (_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_NormalMap);                        SAMPLER(sampler_NormalMap);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);

            
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float2 ParallaxMapping(float2 uv, float3 viewDir_tangent, float scale)
            {
                float3 viewDir = normalize(viewDir_tangent);

                float layerNum = lerp(_MaxLayerNum, _MinLayerNum, abs(dot(float3(0, 0, 1), viewDir)));  //一点优化：根据视角来决定分层数
                float layerDepth = 1.0 / layerNum;

                // 循环次数
                float currentLayerDepth = 0.0;

                float2 deltaTexCoords = viewDir.xy / viewDir.z / layerNum * scale;

                float2 currentTexCoords = uv;
                float currentDepthMapValue =  SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, currentTexCoords).r;

                while(currentLayerDepth < currentDepthMapValue)
                {
                    currentTexCoords += deltaTexCoords;
                    currentDepthMapValue = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, currentTexCoords, 1.0).r;
                    currentLayerDepth += layerDepth;
                }


                return currentTexCoords;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;
                float3x3 tbn = float3x3(o.tangentWS,o.bitangentWS,o.normalWS);
                o.viewDirWS = mul(tbn, GetCameraPositionWS() - PositionInputs.positionWS); 
                return o;   
            }


            half4 frag (v2f i) : SV_Target
            {

                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色


                half3 LightDir = normalize(mylight.direction);                 //获取光照方向
                half3 ViewDir = normalize(i.viewDirWS);                            //在这里计算  视角方向      

                // ==========================================================================================================

                float2 uv = ParallaxMapping(i.uv, ViewDir, _HeightScale * 0.1);


                // ==========================================================================================================
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 NormalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                
                //float3 normalWS = UnpackNormalScale(NormalTex, _NormalScale);   // 使用UnpackNormalScale来获取法线并考虑缩放  
                float3 normalWS = UnpackNormal(NormalTex);
                                         
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 

                half3 diffuseColor = albedo.rgb + (LightColor.rgb  * saturate(dot(normalWS, LightDir)));
                half3 halfDir = normalize(ViewDir + LightDir);
                half3 specularColor = LightColor.rgb * _SpecularColor.rgb * pow(saturate(dot(normalWS, halfDir)), _Gloss);

                half3 finalColor = ambient + diffuseColor + specularColor;
                
                return half4(finalColor, 1.0);

            }
            ENDHLSL
        }
    }
}