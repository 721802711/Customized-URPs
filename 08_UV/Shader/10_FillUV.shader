Shader "B/10_FillUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _ClipUvLeft ("Clipping Left", Range(0, 1)) = 0 //102
        _ClipUvRight ("Clipping Right", Range(0, 1)) = 0 //103
        _ClipUvUp ("Clipping Up", Range(0, 1)) = 0 //104
        _ClipUvDown ("Clipping Down", Range(0, 1)) = 0 //105
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
            half _ClipUvLeft, _ClipUvRight, _ClipUvUp, _ClipUvDown;
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


                half2 tiledUv = half2(i.uv.x / _MainTex_ST.x, i.uv.y / _MainTex_ST.y);
                //通过 (1 - _ClipUvUp) 计算出裁剪的顶部位置，然后与 tiledUv.y 比较，超出这个范围的纹理将被裁剪
                clip((1 - _ClipUvUp) - tiledUv.y);
                //使用 _ClipUvDown 控制裁剪的底部位置
                clip(tiledUv.y - _ClipUvDown);
                //裁剪了纹理的右部分，使用 _ClipUvRight 控制裁剪的右侧位置
                clip((1 - _ClipUvRight) - tiledUv.x);
                //裁剪了纹理的左部分，使用 _ClipUvLeft 控制裁剪的左侧位置
                clip(tiledUv.x - _ClipUvLeft);


                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv); 


                return col;
            }
            ENDHLSL 
        }
    }
} 