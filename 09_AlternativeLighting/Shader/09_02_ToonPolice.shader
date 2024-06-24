Shader "B/09_02_ToonPolice"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("_BaseColor",Color) = (1,1,1,1)
        _AmbientColor("_AmbientColor", Color) = (0,0,0,1)
        _Specular("_Specular", Color) = (0,0,0,1)
        _RimAmount ("_RimAmount", Range(0.2, 1)) = 1
        _Smoothstep ("_Smoothstep", Range(0.01, 0.3)) = 0.1
        _smoothness("_smoothness", Range(0,1)) = 0.5
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
            half4 _BaseColor, _Specular;
            half4 _AmbientColor;
            half _RimAmount, _Smoothstep, _smoothness;
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
                float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
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
                o.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;   //  相机世界位置 - 世界空间顶点位置
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                Light light = GetMainLight();                                // 获取场景主光源
                half3 LightColor = light.color;    
                half3 LightDir = normalize(light.direction);                //获取光照方向
                half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
                half3 attenuatedLightColor = LightColor.rgb * LightAttenuation;                                             // 计算衰减后的光照颜色

                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv); 
                half3 normal = normalize(i.normalWS);                    // 获取法线信息
                half3 viewDir = normalize(i.viewDirWS);
                half NdotL = saturate(dot(normal, LightDir));            // 计算法线和光照方向的夹角

                // 漫反射
                // 当 NdotL 在 [0, 1] 范围内变化时，lightIntensity 将从 0.5 过渡到 1
                float lightIntensity = smoothstep(0, _Smoothstep, NdotL);


                float4 Diffuse = _BaseColor * col * (_AmbientColor + lightIntensity);
                Diffuse.rgb *= attenuatedLightColor;

                // 高光
                float3 halfVec = normalize(LightDir + viewDir); // 半兰伯特向量
                half NdotH = half(saturate(dot(normal, halfVec)));
                half smoothness = exp2(10 * _smoothness + 1);
                half modifier = pow(max(0,NdotH), smoothness);

                // 计算高光强度的平滑过渡值
                half specularIntensity = smoothstep(0.005, 0.01, modifier);
                // 计算高光颜色，乘以平滑过渡值和衰减后的光照颜色
                half3 specularColor = _Specular.rgb * specularIntensity * attenuatedLightColor;


                // 边缘
                float rimDot = 1 - dot(viewDir, normal);
                float rimValue = rimDot * NdotL;

                float rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimValue);
                rimIntensity  *=  _Specular.rgb;

                // 最终颜色输出，将漫反射、高光和边缘光结合起来
                half4 outputColor = Diffuse + half4(specularColor, 0) + rimIntensity;
                return outputColor;
            }
            ENDHLSL
        }
    }
}