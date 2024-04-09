Shader "B/08_TimeUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _ZoomUVAmount ("Zoom Amount", Range(0.1, 5)) = 0.5 //108
        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5   // 源混合模式
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10  // 目标混合模式
    } 
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}
        Blend[_SrcBlend][_DstBlend]

        Cull Off 

        LOD 100 

        HLSLINCLUDE 

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

        CBUFFER_START(UnityPerMaterial) 
            float4 _MainTex_ST;
            half _ZoomUVAmount;
        CBUFFER_END 

        struct appdata 
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;

        };

        struct v2f 
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };

        TEXTURE2D(_MainTex);                   SAMPLER(sampler_MainTex);
        ENDHLSL 

        Pass 
        {
            HLSLPROGRAM 
            
            #pragma vertex vert 
            #pragma fragment frag 


            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz); // 获取顶点位置输入
                o.positionCS = PositionInputs.positionCS; // 获取齐次空间位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // 纹理坐标变换

                return o;
            }

            half4 frag (v2f i, bool face : SV_isFrontFace) : SV_Target 
            {

                float2 uv = i.uv; // 原始UV坐标
                uv -= half2(0.5, 0.5);//将纹理坐标平移到以纹理中心为原点的坐标系中
                uv *= _ZoomUVAmount;  //对纹理坐标进行缩放操作
                uv += half2(0.5, 0.5);//将缩放后的纹理坐标平移到原来的坐标系中心


                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv); 


                return col;
            }
            ENDHLSL 
        }
    }
} 