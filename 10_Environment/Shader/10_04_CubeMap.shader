Shader "B/10_04_CubeMap"
{
    Properties
    {
        [NoScaleOffset]_Cubemap("Cubemap", CUBE) = "" {}
        _Rotation("_Rotation",Range(0,360)) = 0                             //旋转是在360度旋转
        _ReflectBlur("_ReflectBlur", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float _Rotation, _ReflectBlur;
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
                reflectDirWS = RotatAround(_Rotation,reflectDirWS);         //调用这个函数计算出新的反射向量      
      

                half roughness = pow((1 - _ReflectBlur),2);
                roughness = roughness * (1.7 - 0.7 * _ReflectBlur); 
                float MidLevel = roughness * 6;
                //half4 Cube = texCUBE(_CubeMap,reflectDirWS);            // 使用反射向量采样环境贴图
                half4 SampleCubemap = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflectDirWS, MidLevel);
                return SampleCubemap;
            }
            ENDHLSL
        }
    }
}