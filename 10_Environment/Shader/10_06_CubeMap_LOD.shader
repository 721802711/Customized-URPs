Shader "B/10_06_CubeMap_LOD"
{
    Properties
    {
        [NoScaleOffset]_Cubemap("Cubemap", CUBE) = "" {}
        _Rotation("_Rotation",Range(0,360)) = 0                             //旋转是在360度旋转
        _ReflectBlur("_ReflectBlur", Range(0,1)) = 0
        _CubeMapLODBaseLvl ("_CubeMapLODBaseLvl", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float _Rotation, _ReflectBlur;
            float _CubeMapLODBaseLvl;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

        TEXTURECUBE(_Cubemap);       SAMPLER(sampler_Cubemap);

        ENDHLSL


        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影


		    float3 FakeComputeIndirectSpecular(float3 reflectDir, float _ReflectBlur, float _CubeMapLODBaseLvl)
		    {

                
                half roughness = pow((1 - _ReflectBlur),2);
                roughness = roughness * (1.7 - 0.7 * _ReflectBlur); 
                float MidLevel = roughness * 6 + _CubeMapLODBaseLvl;

                half4 SampleCubemap = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflectDir, MidLevel);

                // 限制反射的高光输出 
                SampleCubemap.rgb = saturate(SampleCubemap.rgb);

                return SampleCubemap;
            }



            //-------函数类型--名字（输入数据）
            float3 RotatAround(float degree,float3 target)
            {
                float rad = degree * 3.1415926/180;                               //把弧度转成角度
                float2x2 m_rotate = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));          //构建矩阵
                float2 dir_rotate =mul(m_rotate,target.xz);                    //计算出反射向量
                target = float3(dir_rotate.x ,target.y, dir_rotate.y);     //这个是计算旋转后的，Y轴保持原来的角度
                return target;
                //----返回值
            }

            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                                    
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = normalInputs.normalWS;

                return o;   

            }


            half4 frag (v2f i) : SV_Target
            {


                float3 viewDir = normalize(GetCameraPositionWS().xyz-i.positionWS);
                half3 normalWS = normalize(i.normalWS); 
                float3 reflectDirWS = reflect(-viewDir,normalWS);                     // 计算出反射向量
                reflectDirWS = RotatAround(_Rotation,reflectDirWS);                   //调用这个函数计算出新的反射向量      

                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float shadow = mainLight.shadowAttenuation;
                float ndotl = saturate(dot(mainLight.direction, normalWS));

                float3 ambient = SampleSH(normalWS);

                float3 lightColor = mainLight.color.rgb * ndotl * shadow + ambient;
      

                half3 SampleCubemap = FakeComputeIndirectSpecular(reflectDirWS, _ReflectBlur, _CubeMapLODBaseLvl); // 计算出反射
                float3 color = SampleCubemap.rgb * lightColor; // 采样立方体贴图

                return half4(color.rgb, 1);


            }
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vertShadow
            #pragma fragment fragShadow

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vertShadow(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 lightDir = GetMainLight().direction;
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDir));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                output.positionCS = positionCS;
                return output;
            }

            float4 fragShadow(Varyings input) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }
    }
}