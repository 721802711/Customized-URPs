Shader "10_08_GlassNormalMap"
{
    Properties
    {
        _Matcap ("Texture", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "bump" {} // 新增法线贴图属性
        _RefracMatcap("RefracMatcap", 2D)= "white" {}
        
        _RefracMu("RefracMu", float) = 1
        _Color("Color", Color) = (1,1,1,1)
        _OpacityMu("OpacityMu", float) = 1
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _MatcapMu("MatcapMu", float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha One  


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag   

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct FragmentInput
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;

                float4 tangentWS : TANGENT; // 注意是 float4 类型，W分量储存其他信息
            };



            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _RefracMatcap_ST;
                float4 _NormalMap_ST;
                float _RefracMu;
                float4 _Color;
                float _OpacityMu;
                float4 _BaseColor;
                float _MatcapMu;

            CBUFFER_END

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_RefracMatcap);                    SAMPLER(sampler_RefracMatcap);

            TEXTURE2D(_NormalMap);                       SAMPLER(sampler_NormalMap); // 声明法线贴图

            FragmentInput vert(VertexInput v)
            {
                FragmentInput o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = NormalInputs.normalWS;
                o.tangentWS = float4(NormalInputs.tangentWS, v.tangentOS.w);

                o.uv = TRANSFORM_TEX(v.texcoord, _NormalMap);         
                return o;
            }

            half4 frag(FragmentInput i) : SV_Target
            {

                // 从法线贴图中采样法线向量
                half4 normalMapSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                half3 normalTS = UnpackNormalScale(normalMapSample, 1.0); // 转换法线贴图的颜色值到实际的法线向量

                // 构造切线矩阵
                float3 t = normalize(i.tangentWS.xyz);
                float3 n = normalize(i.normalWS); // 这里使用从顶点着色器传递来的世界空间法线
                float3 b = cross(n, t) * i.tangentWS.w;
                float3x3 tangentMatrix = float3x3(t, b, n);


                // 使用切线矩阵将切线空间的法线转换为世界空间
                half3 normalWS = TransformTangentToWorld(normalTS, tangentMatrix);

                float2 UVandMatCap;
                UVandMatCap.x = dot(normalize(UNITY_MATRIX_IT_MV[0].xyz), normalize(normalWS.xyz));
                UVandMatCap.y = dot(normalize(UNITY_MATRIX_IT_MV[1].xyz), normalize(normalWS.xyz));


                // 使用切线空间的法线计算MatCap的UV坐标
                UVandMatCap = UVandMatCap.xy * 0.5 + 0.5;
                half3 matCapColor = SAMPLE_TEXTURE2D(_RefracMatcap, sampler_RefracMatcap, UVandMatCap).rgb; 


                // 计算折射率
                float3 viewDir = normalize(i.positionWS - _WorldSpaceCameraPos.xyz);


                float VDotN = dot(viewDir, normalWS);
                float Thickness = 1 - smoothstep(0, 1, VDotN);   // 计算厚度
                float2 Refrac_uv = UVandMatCap + Thickness * _RefracMu;  // 计算折射后的UV坐标
                half3 refracColor = SAMPLE_TEXTURE2D(_RefracMatcap, sampler_RefracMatcap, Refrac_uv).rgb; // 采样折射贴图


                float alpha = saturate(max(matCapColor.x, Thickness) * _OpacityMu);


                return float4(refracColor.rgb, alpha);
            }
            ENDHLSL
        }
    }
}