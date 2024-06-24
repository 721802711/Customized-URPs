Shader "B/10_03_ReflectCube"
{
    Properties
    {

        _ReflectBlur("_ReflectBlur", Range( 0 , 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float _ReflectBlur;
            float4 _MainTex_ST;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                                    
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = normalInputs.normalWS;

                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;   

            }


            half4 frag (v2f i) : SV_Target
            {

                float3 viewDir = normalize(GetCameraPositionWS().xyz-i.positionWS);
                half3 normalWS = normalize(i.normalWS); 
                float3 reflectDirWS = reflect(-viewDir,normalWS);                     // 计算出反射向量
      


                float4 CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, _ReflectBlur * 6);   // 使用反射控制Cube等级


                return CubeMapColor;
            }
            ENDHLSL
        }
    }
}