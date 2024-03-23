Shader "B/03_00_SimpleParallax"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0, 3)) = 1
        _HeightMap ("_HeightMap", 2D) = "bump"{}       
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(30, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 1)) = 0.1  
        [KeywordEnum(up, down)] _Parallaxmap ("_Parallaxmap Mode", Float) = 0
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
                float3 viewDirTS: TEXCOORD3;                                       //输出视角方向
                float3 lightDirTS : TEXCOORD2;
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

            #pragma multi_compile _PARALLAXMAP_UP _PARALLAXMAP_DOWN

            float2 ParallaxMapping(float2 uv, float3 viewDir_tangent, float scale)
            {
                float3 viewDir = normalize(viewDir_tangent);
                float Height = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,uv).r;

                float2 p = viewDir.xy / viewDir.z * (Height * scale * 0.1);

                float2 offset = float2(0.0,0.0);
                #ifdef _PARALLAXMAP_UP
                    offset = uv + p;   // 注意这里可以是减 或者是增加，效果是不一样的
                #elif _PARALLAXMAP_DOWN
                    offset = uv - p;   // 注意这里可以是减 或者是增加，效果是不一样的    
                #endif 
                   

                return offset;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息


                Light mainLight = GetMainLight();
                float3x3 tbn = float3x3(NormalInputs.tangentWS, NormalInputs.bitangentWS, o.normalWS);;

                o.lightDirTS = mul(tbn, mainLight.direction);
                o.viewDirTS = mul(tbn, GetCameraPositionWS() - PositionInputs.positionWS); 

                return o;   
            }


            half4 frag (v2f i) : SV_Target
            {

                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色


                half3 lightDirTS = normalize(i.lightDirTS);
                half3 viewDirTS = normalize(i.viewDirTS);                            //在这里计算  视角方向      


                // ==========================================================================================================

                float2 uv = ParallaxMapping(i.uv, viewDirTS, _HeightScale);

                
                // ==========================================================================================================
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 NormalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);

                float3 normalTS = UnpackNormalScale(NormalTex,_NormalScale);             //控制法线强度


                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 

                half3 diffuseColor = LightColor * albedo.rgb * (saturate(dot(normalTS, lightDirTS)) * 0.5 + 0.5) * _DiffuseColor;

                half3 halfDir = normalize(viewDirTS + lightDirTS);
                half3 specularColor = LightColor * _SpecularColor.rgb * pow(saturate(dot(normalTS, halfDir)), _Gloss);

                half3 finalColor = diffuseColor + specularColor + ambient;

                return half4(finalColor, 1.0);

            }
            ENDHLSL
        }
    }
}