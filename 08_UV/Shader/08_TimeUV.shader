Shader "B/08_TimeUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _TextureScrollXSpeed ("Speed X Axis", Range(-5, 5)) = 1 //滚动X轴速度
        _TextureScrollYSpeed ("Speed Y Axis", Range(-5, 5)) = 0 //滚动Y轴速度
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
            half _TextureScrollXSpeed,_TextureScrollYSpeed;
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
                //时间的变化会影响偏移量的计算，从而实现了纹理滚动的效果
                uv.x += (_Time.y * _TextureScrollXSpeed);//根据时间和_TextureScrollXSpeed计算了在x方向上的偏移量
                uv.y += (_Time.y * _TextureScrollYSpeed);//根据时间和_TextureScrollYSpeed计算了在y方向上的偏移量


                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv); 


                return col;
            }
            ENDHLSL 
        }
    }
} 