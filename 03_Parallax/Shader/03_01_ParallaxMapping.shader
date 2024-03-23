Shader "B/03_01_ParallaxMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}    
        _HeightScale ("Height Scale", Range(0, 10)) = 1
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
        float4 _MainTex_ST, _HeightMap_ST;
        float _HeightScale;
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

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _PARALLAXMAP_UP _PARALLAXMAP_DOWN



            half2 ParallaxOffset1Step(half height, half amplitude, half3 viewDirTS)
            {
                height = height * amplitude - amplitude / 2.0;       // 调整高度值，使其在振幅范围内
                half3 v = normalize(viewDirTS);
                v.z += 0.42;
                return height * (v.xy / v.z);
            }

            float2 ParallaxMapping(half3 viewDirTS, half scale, float2 uv)
            {

                float3 viewDir = normalize(viewDirTS);
                float h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv).g;

                // 因为viewDir是在切线空间的（xy与uv对齐），所以只用xy偏移就行了
                float2 height = ParallaxOffset1Step(h, scale, viewDir);

                float2 offset = float2(0.0,0.0);

                #ifdef _PARALLAXMAP_UP
                    offset = uv + height;   // 注意这里可以是减 或者是增加，效果是不一样的
                #elif _PARALLAXMAP_DOWN
                    offset = uv - height;   // 注意这里可以是减 或者是增加，效果是不一样的
                #endif

                return offset;
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
                half4 LightColor = half4(mylight.color,1);                     //获取主光源的颜色


                half3 LightDir = normalize(mylight.direction);                 //获取光照方向
                half3 viewDirTS = normalize(i.viewDirWS);                            //在这里计算  视角方向      

                float2 uv = ParallaxMapping(viewDirTS, _HeightScale * 0.01, i.uv);
				if(uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0) //去掉边上的一些古怪的失真，在平面上工作得挺好的
				discard;
                
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                return albedo;
            }
            ENDHLSL
        }
    }
}