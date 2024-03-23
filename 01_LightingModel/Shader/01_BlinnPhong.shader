Shader "B/01_BlinnPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _gloss("_gloss",Float) = 0.2
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
                float3 viewDirWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _gloss;
            CBUFFER_END


            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz,true);
                o.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(v.positionOS.xyz));
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                half4 DiffuseTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);     //贴图采样变成3个变量
                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色
                

                float3 ViewDir = normalize(i.viewDirWS);                       //归一化视角方向
                float3 NormalDir = normalize(i.normalWS);                      
                float3 LightDir = normalize(mylight.direction);                //获取光照方向

                float3 ReflectDir = normalize(reflect(-LightDir,NormalDir));     //反射方向

                float LdotN = dot(LightDir,NormalDir) * 0.5 + 0.5;              //LdotN

                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 

                half3 specularValue = pow(max(0,dot(ReflectDir,ViewDir)),_gloss) * LightColor.rgb;   // 高光
                half3 diffusecolor = DiffuseTex * LdotN * LightColor;
                half4 col =  half4(specularValue + diffusecolor + ambient, 1.0);


                return col;
            }
            ENDHLSL
        }
    }
}