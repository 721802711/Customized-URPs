Shader "B/01_Lanbert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                float4 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息

            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END


            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz,true);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                Light mylight = GetMainLight();                                //获取场景主光源
                real4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色
                float3 LightDir = normalize(mylight.direction);                //获取光照方向
                float LdotN = dot(LightDir,i.normalWS);                        //LdotN

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);     //贴图采样变成3个变量

                return col * LdotN * LightColor;
            }
            ENDHLSL
        }
    }
}