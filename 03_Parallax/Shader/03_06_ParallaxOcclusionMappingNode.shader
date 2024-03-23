Shader "B/03_06_ParallaxOcclusionMappingNode"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("_HeightMap", 2D) = "bump"{}    
        _NormalMap ("_NormalMap", 2D) = "bump" { }
        _NormalScale ("Normal Scale", Range(0, 3)) = 1
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(30, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 10)) = 1
        _Steps ("_Steps", Range(1,30)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _HeightMap_ST, _NormalMap_ST;
        float _HeightScale;
        float _Steps;
        float4 _SpecularColor;
        float _Gloss;
        float _NormalScale;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;                                       //输出世界空间下法线信息
                float3 tangentWS :TANGENT;                                         //注意 是 float4 类型，W分量储存其他信息
                float3 bitangentWS : TEXCOORD2;                                     //注意 是 float4 类型，W分量储存其他信息
                float3 viewDirWS: TEXCOORD3;                                       //输出视角方向
            };

            struct PerPixelHeightDisplacementParam
            {
                float2 uv;
            };


            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D (_HeightMap);                        SAMPLER(sampler_HeightMap);
            TEXTURE2D (_NormalMap);                        SAMPLER(sampler_NormalMap);

            // ComputePerPixelHeightDisplacement 函数实现
            float ComputePerPixelHeightDisplacement(float2 uvOffset, float lod, PerPixelHeightDisplacementParam ppdParam)
            {
                // 这里应该是高度图的采样逻辑
                return SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, ppdParam.uv + uvOffset).r;
            }


        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"


            float3 GetDisplacementObjectScale()
            {

                float3 objectScale = float3(1.0, 1.0, 1.0);
                float4x4 worldTransform = GetWorldToObjectMatrix();

                objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                return objectScale;
            }




            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;
                float3x3 tbn = float3x3(o.tangentWS,o.bitangentWS,o.normalWS);
                o.viewDirWS = mul(tbn, GetCameraPositionWS() - PositionInputs.positionWS); 

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {


                Light mylight = GetMainLight();                                //获取场景主光源
                half4 LightColor = half4(mylight.color,1);                     //获取主光源的颜色


                half3 LightDir = normalize(mylight.direction);                 //获取光照方向
                half3 viewDir = normalize(i.viewDirWS);                            //在这里计算  视角方向    
                // ==========================================================================================================

                // 计算视差偏移量
                float3 _ViewDir = viewDir * GetDisplacementObjectScale().xzy; 

                // 计算视差遮蔽映射
                float MaxHeight = _HeightScale * 0.01;
                MaxHeight *= 2.0/(abs(float2 (1, 1).x) + abs(float2 (1, 1).y));   // 根据纹理的尺寸调整最大高度

                float2 UV = i.uv * float2 (1, 1) + float2 (0, 0);      // 计算当前片段的 UV 坐标

                float2 _UVspaceScale = MaxHeight * float2 (1, 1) / float2 (1, 1);  // 算 UV 空间的缩放比例

                float3 ViewDirUV    = normalize(float3(_ViewDir.xy * _UVspaceScale, _ViewDir.z));     // 计算视差方向在 UV 空间中的单位向量

                PerPixelHeightDisplacementParam _POM;  // 视差遮蔽映射的参数结构体
                _POM.uv = UV;                          // 将 UV 坐标赋值给参数结构体

                // 函数计算视差偏移量
                float OutHeight;
                float2 parallaxOffset = ParallaxOcclusionMapping(0, 0, max(min(_Steps, 256), 1), ViewDirUV, _POM, OutHeight);
                // ==========================================================================================================
                float2 uv = i.uv + parallaxOffset;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 NormalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);

                float3 normalWS = UnpackNormalScale(NormalTex, _NormalScale);   // 使用UnpackNormalScale来获取法线并考虑缩放  

                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   // 环境光 
                half3 diffuseColor = albedo.rgb + (LightColor.rgb  * saturate(dot(normalWS, LightDir)));
                half3 halfDir = normalize(viewDir + LightDir);
                half3 specularColor = LightColor.rgb * _SpecularColor.rgb * pow(saturate(dot(normalWS, halfDir)), _Gloss);
                
                half3 finalColor = ambient + diffuseColor + specularColor;

                return float4(finalColor.rgb,1);
            }
            ENDHLSL
        }
    }
}