Shader "B/02_ParallaxOcclusion"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "bump" { }
        _HeightMap ("_HeightMap", 2D) = "bump"{}
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(32, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 1)) = 0.1
        _amplitude ("_amplitude", Range(1 , 30)) = 1
        _MaxLayerNum ("Max Layer Num", Float) = 80
        _MinLayerNum ("Min Layer Num", Float) = 30
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
                float2 uv : TEXCOORD0;                                             //float4类型的UV数据，
                float4 positionCS : SV_POSITION;
                float3 lightDirTS : TEXCOORD1;
                float3 viewDirTS: TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST,_NormalMap_ST, _HeightMap_ST;
                float _HeightScale, _Gloss, _Scale;
                float4 _DiffuseColor, _SpecularColor;
                float4 _HeightMap_TexelSize;
                float _amplitude;
                float _MaxLayerNum;
                float _MinLayerNum;
            CBUFFER_END


            TEXTURE2D (_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_NormalMap);                        SAMPLER(sampler_NormalMap);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);

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
                float2 UV_TO = _HeightMap_ST.xy + _HeightMap_ST.zw;
                float h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv * UV_TO).g;


                // 因为viewDir是在切线空间的（xy与uv对齐），所以只用xy偏移就行了
                float2 height = ParallaxOffset1Step(h, scale, viewDir);

                float2 offset = uv + height;
                return offset;
            }

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = vertexInputs.positionCS;

                o.uv = v.texcoord;                                    //xy分量，储存颜色贴图uv


                Light mainLight = GetMainLight();
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                float3x3 tbn = float3x3(normalInputs.tangentWS,normalInputs.bitangentWS,normalInputs.normalWS);
                o.lightDirTS = mul(tbn,mainLight.direction);    
                o.viewDirTS = mul(tbn, GetCameraPositionWS() - vertexInputs.positionWS); 
                return o;

            }

            half4 frag (v2f i) : SV_Target
            {

                float3 lightDirTS = normalize(i.lightDirTS);
                float3 viewDirTS = normalize(i.viewDirTS);

                float2 uv = ParallaxMapping(viewDirTS, _HeightScale * 0.1, i.uv);

                half4 packedNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv * _NormalMap_ST.xy + _NormalMap_ST.zw);
                float3 normalTS = UnpackNormal(packedNormal);

                float LdotN = dot(normalTS,lightDirTS)* 0.5 + 0.5;                      //LdotN    这里使用新的法线信息。

                Light mainLight = GetMainLight();



                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv * _MainTex_ST.xy + _MainTex_ST.zw ) * _DiffuseColor;     //贴图采样变成3个变量
                half3 diffuseColor = mainLight.color * albedo.rgb * saturate(LdotN);

                half3 halfDir = normalize(viewDirTS + lightDirTS);
                half3 specularColor = mainLight.color * _SpecularColor.rgb * pow(saturate(dot(normalTS, halfDir)), _Gloss);
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 

                half3 finalColor =  diffuseColor + specularColor + ambient;


                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}