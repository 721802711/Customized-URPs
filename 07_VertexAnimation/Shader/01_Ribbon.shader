Shader "B/01_Ribbon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Amplitude ("Amplitude", Range(0, 1)) = 0.5
        _MoveSpeed ("Move Speed", Range(1, 3)) = 1
        _Scale ("Scale", Range(0, 30)) = 1

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
        float4 _MainTex_ST;
        float _MoveSpeed, _Scale, _Amplitude;
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

                v.positionOS.y +=  _Amplitude * 0.5 * sin(v.positionOS.x * _Scale +  _Time.y * _MoveSpeed) *  v.texcoord.y;
                v.positionOS.x +=  _Amplitude  * sin(v.positionOS.z * _Scale +  _Time.y * _MoveSpeed) *  v.texcoord.y;


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