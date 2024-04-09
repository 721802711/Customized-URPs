Shader "B/07_ShadeUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _ShakeUvSpeed ("Shake Speed", Range(0, 20)) = 2.5 //抖动速度
        _ShakeUvX ("X Multiplier", Range(0, 30)) = 1.5 //x轴抖动幅度
        _ShakeUvY ("Y Multiplier", Range(0, 30)) = 1 //y轴抖动幅度
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
            half _ShakeUvSpeed, _ShakeUvX, _ShakeUvY;
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

                half xShake = sin(_Time * _ShakeUvSpeed * 50) * _ShakeUvX;//根据时间，速度和振幅计算了在x方向上的振动量。使用正弦函数来产生周期性的振动效果
                half yShake = cos(_Time * _ShakeUvSpeed * 50) * _ShakeUvY;//根据时间，速度和振幅计算了在y方向上的振动量。使用余弦函数来产生周期性的振动效果
                i.uv += half2(xShake * 0.01, yShake * 0.01);//将计算得到的振动量应用到当前像素的纹理坐标上


                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv); 


                return col;
            }
            ENDHLSL 
        }
    }
} 