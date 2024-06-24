Shader "B/05_2DGlow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlowColor ("Glow Color", Color) = (1, 1, 1, 1) //全身发光的颜色
        _GlowIntensity ("GlowIntensity", Range(0, 10)) = 2 //纹理或者颜色运用部位的发光的强度
        [NoScaleOffset] _GlowTex ("GlowTexture", 2D) = "white" { }//发光纹理

        _DistortTex ("DistortionTex", 2D) = "white" { }//发光纹理扭曲的噪声图
        _DistortAmount ("DistortionAmount", Range(0, 2)) = 2 //噪声图波动的大小系数
        _DistortTexXSpeed ("DistortTexXSpeed", Range(-50, 50)) = 0 //噪声图波动的X轴速度
        _DistortTexYSpeed ("DistortTexYSpeed", Range(-50, 50)) = -5 //噪声图波动的Y轴速度

        [Space(20)]

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _cull ("cull Mode", Float) = 0 
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}

        LOD 100


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _GlowColor;
            float _GlowIntensity;
            float4 _DistortTex_ST;
            float _DistortTexXSpeed, _DistortTexYSpeed, _DistortAmount;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_GlowTex);                          SAMPLER(sampler_GlowTex);
            TEXTURE2D(_DistortTex);                          SAMPLER(sampler_DistortTex);

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
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DistortTex);//得到_DistortTex空间下的uv坐标
                o.color = v.color;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);

                i.uv.z += (_Time * _DistortTexXSpeed) % 1;//将噪声纹理图和时间成比例进行移动
                i.uv.w += (_Time * _DistortTexYSpeed) % 1;
                float outDistortAmnt = (SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv.zw).r - 0.5) * 0.2 * _DistortAmount;//通过采样噪声图的r值来得到变形的大小参数
                float2 destUv = (0, 0);
                destUv.x += outDistortAmnt;//描边空间的xy加上这个变形的参数，使描边变形
                destUv.y += outDistortAmnt;
                float4 noiseCol = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, destUv);

                float4 emission = SAMPLE_TEXTURE2D(_GlowTex, sampler_GlowTex, i.uv);//再对发光纹理图采样得到发光的颜色
                emission.rgb *= emission.a * col.a * _GlowIntensity * _GlowColor;//再乘以发光的强度和发光的颜色得到一个我们可以通过数据控制的颜色
                col.rgb += emission.rgb * noiseCol * i.color.rgb;//再让原本颜色加上发光颜色再加上扭曲颜色
                col.a = col.a * i.color.a;

                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}