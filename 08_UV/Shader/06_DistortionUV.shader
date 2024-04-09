Shader "B/06_DistortionUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _DistortTex ("Distortion Texture", 2D) = "white" { }//扭曲的噪声图
        _DistortAmount ("Distortion Amount", Range(0, 2)) = 0.5 //扭曲的程度
        _DistortTexXSpeed ("Scroll speed X", Range(-10, 10)) = 5 //x轴速度
        _DistortTexYSpeed ("Scroll speed Y", Range(-10, 10)) = 5 //y轴速度

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
            float4 _MainTex_ST, _DistortTex_ST;
            half _DistortTexXSpeed, _DistortTexYSpeed, _DistortAmount;
            float _Speed;
        CBUFFER_END 

        struct appdata 
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;

        };

        struct v2f 
        {
            float4 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };

        TEXTURE2D(_MainTex);                   SAMPLER(sampler_MainTex);
        TEXTURE2D(_DistortTex);                  SAMPLER(sampler_DistortTex);

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

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex); // 纹理坐标变换
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DistortTex); // 纹理坐标变换

                return o;
            }

            half4 frag (v2f i, bool face : SV_isFrontFace) : SV_Target 
            {

                float2 Mainuv = i.uv.xy; // 原始UV坐标
                float2 Disuv = i.uv.zw; // 原始UV坐标


                Disuv.x += (_Time.y * _DistortTexXSpeed) % 1;//根据时间控制了对扭曲纹理的采样位置。通过取模运算，确保了采样位置在[0, 1]范围内
                Disuv.y += (_Time.y * _DistortTexYSpeed) % 1;//同理

                //根据从噪声图中r进行扭曲强度的计算 -0.5是要将[0,1]映射到[-0.5, 0.5]
                half distortAmnt = (SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, Disuv).r - 0.5) * 0.2 * _DistortAmount;

                // 主贴图
                Mainuv += distortAmnt;
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,Mainuv); 


                return col;
            }
            ENDHLSL 
        }
    }
} 