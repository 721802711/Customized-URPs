Shader "B/05_2DOutine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("OutlineColor", Color) = (1, 1, 1, 1) //描边颜色
        _OutlineAlpha ("OutlineAlpha", Range(0, 1)) = 1 //描边透明度
        _OutlinePixelWidth ("OutlinePixelWidth", Int) = 1 //描边像素点

        _OutlineDistortTex ("OutlineDistortionTex", 2D) = "white" { }//描边的变形的噪声图
        _OutlineDistortAmount ("OutlineDistortionAmount", Range(0, 2)) = 0.5 //噪声图波动的大小系数
        _OutlineDistortTexXSpeed ("OutlineDistortTexXSpeed", Range(-50, 50)) = 5 //噪声图波动的X轴速度
        _OutlineDistortTexYSpeed ("OutlineDistortTexYSpeed", Range(-50, 50)) = 5 //噪声图波动的Y轴速度
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
            float4 _OutlineColor;
            float _OutlineAlpha;
            int _OutlinePixelWidth;
            float4 _OutlineDistortTex_ST;
            float _OutlineDistortTexXSpeed, _OutlineDistortTexYSpeed, _OutlineDistortAmount;
            float4 _MainTex_TexelSize;//_MainTex纹理的每个像素的尺寸
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

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_OutlineDistortTex);                          SAMPLER(sampler_OutlineDistortTex);
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
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _OutlineDistortTex);//得到_OutlineDistortTex空间下的uv坐标
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                float originalAlpha = col.a;//原始的alpha值

                float2 destUv = float2(_OutlinePixelWidth * _MainTex_TexelSize.x, _OutlinePixelWidth * _MainTex_TexelSize.y);//得到描边空间的像素大小
                i.uv.z += (_Time * _OutlineDistortTexXSpeed) % 1;//将噪声纹理图和时间成比例进行移动
                i.uv.w += (_Time * _OutlineDistortTexYSpeed) % 1;

                //通过采样噪声图的r值来得到变形的大小参数
                float outDistortAmnt = (SAMPLE_TEXTURE2D(_OutlineDistortTex, sampler_OutlineDistortTex, i.uv.zw).r - 0.5) * 0.2 * _OutlineDistortAmount;
                destUv.x += outDistortAmnt;//描边空间的xy加上这个变形的参数，使描边变形
                destUv.y += outDistortAmnt;


                //得到八个方向的外描边的边界值的alpha值 因为是外描边所以要加上destUv组成的float2值
                float spriteLeft = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(destUv.x, 0)).a;
                float spriteRight = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - float2(destUv.x, 0)).a;
                float spriteBottom = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(0, destUv.y)).a;
                float spriteTop = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - float2(0, destUv.y)).a;
                float spriteTopLeft = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(destUv.x, destUv.y)).a;
                float spriteTopRight = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-destUv.x, destUv.y)).a;
                float spriteBotLeft = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(destUv.x, -destUv.y)).a;
                float spriteBotRight = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-destUv.x, -destUv.y)).a;

                float result = spriteLeft + spriteRight + spriteBottom + spriteTop + spriteTopLeft + spriteTopRight + spriteBotLeft + spriteBotRight;


                result = step(0.05, saturate(result));//如果最后的结果alpha值大于0.05，则为1，否则就是0（也就是边界判定）
                result *= (1 - originalAlpha) * _OutlineAlpha;//控制描边的alpha值

                float4 outline = _OutlineColor;//描边的颜色
                col = lerp(col, outline, result);//插值采样得到最后的颜色

                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }
}