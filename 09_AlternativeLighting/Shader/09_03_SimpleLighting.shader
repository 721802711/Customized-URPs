Shader "B/09_03_SimpleLighting"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _smoothness ("Gloss", Range(0, 1)) = 0.5
        [HDR]_SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _AmbientColor ("Ambient Color", Color) = (1,1,1,1)

        _CutOff("CutOff", Range(0.0, 1)) = 0.5

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include"SimpleLit/LightingFun.hlsl"


        struct appdata
        {
            float4 positionOS: POSITION;
            float3 normalOS: NORMAL;
            float4 tangentOS: TANGENT;
            float2 texcoord      : TEXCOORD0;   // 纹理坐标
        };

        struct v2f
        {
            float2 uv        : TEXCOORD0; // 纹理坐标
            float4 positionCS: SV_POSITION;
            float3 positionWS: TEXCOORD1;
            float3 normalWS: NORMAL;
            float3 viewDirWS: TEXCOORD2;
        };

        ENDHLSL


        Pass
        {

            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normalInput.normalWS;                                //  获取世界空间下法线信息

                o.viewDirWS = GetCameraPositionWS() - positionInputs.positionWS;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);     

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.positionWS.xyz));                                // 获取场景主光源

                half3 ViewDir = normalize(i.viewDirWS);                       //归一化视角方向
                half3 NormalDir = normalize(i.normalWS);                      

                // 基础贴图
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);     //贴图采样变成3个变量
                // 计算颜色
                half3 col = B_LightingData(mylight, NormalDir, ViewDir, albedo.rgb);
                half alpha = albedo.a;

                clip(alpha - _CutOff);

                return half4(col, alpha);
            }
            ENDHLSL
        }

        // 阴影计算
        Pass 
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster"}
            ColorMask 0 
            Cull [_Cull]


            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "SimpleLit/ShadowPass.hlsl"           // 函数库


            ENDHLSL
        }

    }
}