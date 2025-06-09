Shader "10_08_GlassNormalCUBE"
{
    Properties
    {
        _Matcap ("Matcap", 2D) = "white" {}
        _MatcapMu("MatcapMu", Range(0,1.5)) = 1
        _MatcapColor("Matcap Color", Color) = (0,0,0,0)
        _NormalMap("Normal Map", 2D) = "bump" {} // 新增法线贴图属性
        [NoScaleOffset]_RefracMatcap("RefracMatcap", CUBE) = "" {}
        _ReflectBlur("ReflectBlur", Range(0,1)) = 0
        _RefracMu("RefracMu", Range(0,1)) = 1
        _OpacityMu("OpacityMu", Range(0,10)) = 1


        _BaseColor("BaseColor",Color) = (0,0,0,0)

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
                float _ReflectBlur;
                float4 _MatcapColor;
                float _OpacityMu;
                float4 _BaseColor;
                float _MatcapMu;
                float _CubeMapLODBaseLvl; // 新增属性，用于控制 Cube Map 的 LOD 基础级别
            CBUFFER_END

            TEXTURE2D(_Matcap);                          SAMPLER(sampler_Matcap);
            TEXTURE2D(_NormalMap);                       SAMPLER(sampler_NormalMap); // 声明法线贴图

            TEXTURECUBE(_RefracMatcap);                  SAMPLER(sampler_RefracMatcap);


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


                float3 positionWS = i.positionWS;
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - positionWS);

                // 将世界空间法线转换到视图空间
                float3 normalVS = normalize(mul(UNITY_MATRIX_V, float4(normalWS, 0.0)).xyz);
                // 顶点位置从世界空间转换成对象空间
                float3 positionOS = mul(unity_WorldToObject, float4(positionWS, 1.0)).xyz;
                // 将对象空间的顶点位置转换到视图空间
                float3 positionVS = normalize(mul(UNITY_MATRIX_MV, float4(positionOS, 1.0)).xyz);


                // 计算 Matcap UV
                float3 posxnormal = cross(normalVS, positionVS);
                float2 append_yx = float2(-posxnormal.y, posxnormal.x);  // 提取并调整分量
                float2 scale_offset = append_yx * 0.5 + 0.5; // 将 UV 坐标从 [-1, 1] 映射到 [0, 1]

                float4 MatcapCol = SAMPLE_TEXTURECUBE(_Matcap, sampler_Matcap, scale_offset) * _MatcapMu;

                // 计算视线方向和法线的点积
                float VDotN = dot(viewDirWS, normalWS);
                float Thickness = 1 - smoothstep(0.0, 1.0, VDotN);

                // 计算折射后的 UV 坐标（这里使用 Cube Map 的方向向量）
                float3 refracDir = reflect(-viewDirWS, normalWS) + Thickness * _RefracMu;

                half roughness = pow((1 - _ReflectBlur),2);
                roughness = roughness * (1.7 - 0.7 * _ReflectBlur); 
                float MidLevel = roughness * 6;

                // 从 Cube Map 中采样折射颜色
                float4 RefracMatcap = SAMPLE_TEXTURECUBE_LOD(_RefracMatcap, sampler_RefracMatcap, refracDir, MidLevel);


                // 线性插值计算厚度影响的颜色
                float4 lerp_thickness = lerp(_MatcapColor, RefracMatcap, Thickness * _RefracMu);

                // 计算最终输出颜色
                float4 output_color = (lerp_thickness + MatcapCol) - _BaseColor;

                float alpha = saturate(max(MatcapCol.x, Thickness) * _OpacityMu);

                return float4(output_color.rgb, alpha);
            }
            ENDHLSL
        }
    }
}