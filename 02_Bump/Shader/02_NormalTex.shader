Shader "B/02_NormalTex"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex ("_NormalTex", 2D) = "bump"{}
        _NormalScale("_NormalScale",Range(0,3)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        Pass
        {
            Tags{ "LightMode"="UniversalForward" }



            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;                                             //float4类型的UV数据，
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
                float3 tangentWS :TANGENT;                                         //注意 是 float4 类型，W分量储存其他信息
                float3 bitangentWS : TEXCOORD2;                                     //注意 是 float4 类型，W分量储存其他信息
                float3 viewDirWS: TEXCOORD3;                                       //输出视角方向
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST,_NormalTex_ST;
                float _NormalScale;
                float4 _DiffuseColor;
            CBUFFER_END


            TEXTURE2D (_MainTex);
            TEXTURE2D (_NormalTex);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_NormalTex);


            v2f vert (appdata v)
            {
                v2f o;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);                                    //xy分量，储存颜色贴图uv
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex);                                  //zw分量，储存法线贴图uv

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;

                o.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;   //  相机世界位置 - 世界空间顶点位置
                return o;   

            }

            half4 frag (v2f i) : SV_Target
            {

                half4 DiffuseTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);     //贴图采样变成3个变量
                half4 NormalTex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv.zw);   //法线贴图


                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = float4(mylight.color,1);                     //获取主光源的颜色
                half3 LightDir = normalize(mylight.direction);                 //获取光照方向
                
                // ==========================================================================================================


                float3x3 TBN = {i.tangentWS.xyz,i.bitangentWS.xyz,i.normalWS.xyz};          //世界空间法线方向

                half3 normalTS = UnpackNormalScale(NormalTex, _NormalScale);   // 使用UnpackNormalScale来获取法线并考虑缩放                                                 
                //normalTS.z = pow((1 - pow(normalTS.x,2) - pow(normalTS.y,2)),0.5);         //规范化法线

                float3 normalWS = mul(normalTS,TBN);                                          //顶点法线，和法线贴图融合 == 世界空间的法线信息  

                // ==========================================================================================================

                half3 ViewDir = normalize(i.viewDirWS);                            //在这里计算  视角方向                   
                half3 halfDir = normalize(ViewDir + LightDir);                      //半角向量

                float LdotN = dot(LightDir,normalWS) * 0.5 + 0.5;                      //LdotN    这里使用新的法线信息。

                // ==========================================================================================================
                half3 diffusecolor = DiffuseTex * LdotN * mylight.color.rgb * _DiffuseColor;

                half4 col = float4(0,0,0,0);
                col.rgb = normalWS;
                col.a = 1;
                return col;
            }
            ENDHLSL
        }
    }
}