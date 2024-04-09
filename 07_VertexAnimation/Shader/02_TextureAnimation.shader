Shader "B/02_TextureAnimation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("HeightMap", 2D) = "white" {}

        _Dir ("Dir", vector) = (1,1,1,1)
        _Flowx ("Flowx" , float) = 0
        _Flowy ("Flowy" , float) = 0      

        [Space(20)]     
		[Enum(UnityEngine.Rendering.CullMode)] _cull("Cull Mode", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _HeightMap_ST;
        float _Flowy, _Flowx;
        float4 _Dir;
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
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_HeightMap);                          SAMPLER(sampler_HeightMap);

        ENDHLSL


        Pass
        {

            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (appdata v)
            {
                v2f o;

                float2 offcetUV = TRANSFORM_TEX(v.texcoord, _HeightMap) + float2(_Flowx, _Flowy) * _Time.y;

                float3 height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, offcetUV, 0); // 假设高度值存储在红色通道

                v.positionOS.x += (_Dir.x * 0.1) * height.x;
                v.positionOS.y += (_Dir.y * 0.1) * height.y;
                v.positionOS.z += (_Dir.z * 0.1) * height.z;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz); // 获取顶点位置输入
                o.positionCS = PositionInputs.positionCS;    // 转换到齐次空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                return col;
            }
            ENDHLSL
        }
    }
}