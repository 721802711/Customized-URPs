Shader "B/02_BumpMap"
{
    Properties
    {
        _DiffuseColor("_DiffuseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}
        _Scale("_Scale",Range(0,100.0)) = 1
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
                float3 lightDirTS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST,_HeightMap_ST;
                float _Scale;
                float4 _DiffuseColor;
                float4 _HeightMap_TexelSize;
            CBUFFER_END


            TEXTURE2D (_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);

            float3 CalculateNormal(float2 uv)
            {
                float2 du = float2(_HeightMap_TexelSize.x * 0.5,0);
                float u1 = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,uv - du).r;
                float u2 = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,uv + du).r;
                float3 tu = float3(1,0,(u2 - u1)*_Scale);

                float2 dv = float2(0,_HeightMap_TexelSize.y * 0.5);
                float v1 = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,uv - dv).r;
                float v2 = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,uv + dv).r;
                float3 tv = float3(0,1,(v2 - v1)*_Scale);

                return normalize(-cross(tu,tv));
            }
            

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);                  
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);                                    //xy分量，储存颜色贴图uv
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _HeightMap);                                  //zw分量，储存高度贴图uv


                Light mainLight = GetMainLight();
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                float3x3 tbn = float3x3(normalInputs.tangentWS,normalInputs.bitangentWS,normalInputs.normalWS);
                o.lightDirTS = mul(tbn,mainLight.direction);    

                return o;

            }

            half4 frag (v2f i) : SV_Target
            {

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy) * _DiffuseColor;     //贴图采样变成3个变量

                float3 lightDirTS = normalize(i.lightDirTS);
                float3 normalTS = CalculateNormal(i.uv.zw);        // 高度贴图转换成法线贴图


                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);    // 环境光

                float LdotN = saturate(dot(normalTS, -lightDirTS)) *  0.5 + 0.5;

                Light mainLight = GetMainLight();
                half3 diffuseColor = mainLight.color * albedo.rgb * LdotN;         // 应用 高度转法线效果
                half4 col = half4(diffuseColor, 1); 


                return col;
            }
            ENDHLSL
        }
    }
}