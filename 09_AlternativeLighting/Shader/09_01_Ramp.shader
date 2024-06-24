Shader "B/09_01_Ramp"
{
    Properties
    {
        _BaseColor("_BaseColor",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Texture", 2D) = "white" {}
        _intensity("intensity",Range(0,5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            half _intensity;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS      : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                half3  normalWS                : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_RampTex);                          SAMPLER(sampler_RampTex);
        ENDHLSL


        Pass
        {

            Tags{ "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置


                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                Light light = GetMainLight();                                // 获取场景主光源
                half3 LightColor = light.color;    
                half3 LightDir = normalize(light.direction);                //获取光照方向
                half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
                half3 attenuatedLightColor = LightColor.rgb;                                             // 计算衰减后的光照颜色

                half3 NormalDir = normalize(i.normalWS);                    // 获取法线信息
            
                // l dot N
                half ndotl = saturate(dot(NormalDir, LightDir) * 0.5 + 0.5) * LightAttenuation;            // 计算光照强度

                half3 Dcol = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(ndotl,0.5));
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _BaseColor.rgba;           // 获取纹理颜色
                col.rgb *= Dcol * _intensity;                                                        // 计算最终颜色
                

                return col;
            }
            ENDHLSL
        }
    }
}