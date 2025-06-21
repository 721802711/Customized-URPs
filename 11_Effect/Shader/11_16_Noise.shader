Shader "B/11_16_Noise"
{
    Properties
    {
        [HDR]_Color("Color", Color) = (0.5,0.5,0.5,1) // 主颜色（支持HDR），用于整体着色和发光调制，影响最终 emissive 输出。
        _tex_ang("tex_ang", Range(0, 360)) = 0 // 主纹理旋转角度，单位为度（0~360），用于控制主纹理的旋转变换。
        _tex_u("tex_u", Float) = 0 // 主纹理在U轴上的动画速度（UV偏移速度），可用于制作纹理横向滚动。
        _tex_v("tex_v", Float) = 0 // 主纹理在V轴上的动画速度（UV偏移速度），可用于制作纹理纵向滚动。
        _Tex("Tex", 2D) = "white" {} // 主纹理贴图，用于最终的图案显示、发光和遮罩控制。
        _noise_qiangdu("noise_qiangdu", Range(0, 1)) = 0.114 // 噪声扰动强度（0~1），控制噪声对主纹理UV偏移的影响程度。
        _noise("noise", 2D) = "white" {} // 噪声贴图，参与扰动主纹理UV，实现动态扭曲等视觉效果。
        _noise_uv("noise_uv", Vector) = (0,0,0,0) // 噪声的UV动画控制参数（x 为U方向速度，y 为V方向速度），用于动态噪声扰动。
        [MaterialToggle] _Auto("Auto", Float) = 0 // 自动启用范围遮罩开关（0 或 1），控制是否启用圆形遮罩模拟径向渐变。
        _Power("Power", Float) = 1.5 // 遮罩的衰减强度（用于自动遮罩模式），值越大中心越亮边缘越暗。
        _mask("mask", 2D) = "white" {} // 遮罩贴图，用于控制透明度或遮挡效果，可与自动遮罩混合。
        _mask_ang("mask_ang", Float) = 0 // 遮罩贴图的旋转角度（单位：度），用于控制遮罩贴图旋转方向。
        _noise_ang("noise_ang", Float) = 90 // 噪声贴图的旋转角度（单位：度），影响噪声扰动方向。
        _GrayRange("Gray Range", Range(0, 1)) = 0 // 灰度化强度（0~1），0 为彩色，1 为完全灰度，可用于风格切换或特效变换。
        _Clip("Clip", Vector) = (-10000,-10000,10000,10000) // 屏幕裁剪区域（XY为左下，ZW为右上），用于控制片元是否被裁剪（当前未使用，可扩展）。

    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha One
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _tex_ang;
            float _tex_u;
            float _tex_v;
            float _noise_qiangdu;
            float4 _noise_uv;
            float _Auto;
            float _Power;
            float _mask_ang;
            float _noise_ang;
            float _GrayRange;
            float4 _Clip;
            float4 _Tex_ST;
            float4 _noise_ST;
            float4 _mask_ST;
            CBUFFER_END

            TEXTURE2D(_Tex); SAMPLER(sampler_Tex);
            TEXTURE2D(_noise); SAMPLER(sampler_noise);
            TEXTURE2D(_mask); SAMPLER(sampler_mask);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 posWS : TEXCOORD1;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.posWS = mul(unity_ObjectToWorld, v.positionOS);
                o.uv = v.uv;
                o.color = v.color;

                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 piv = float2(0.5, 0.5);

                float tex_ang_rad = radians(_tex_ang);
                float2x2 tex_rot = float2x2(cos(tex_ang_rad), -sin(tex_ang_rad), sin(tex_ang_rad), cos(tex_ang_rad));

                float noise_ang_rad = radians(_noise_ang);
                float2x2 noise_rot = float2x2(cos(noise_ang_rad), -sin(noise_ang_rad), sin(noise_ang_rad), cos(noise_ang_rad));

                float2 noise_uv = mul(i.uv - piv, noise_rot) + piv + float2(_noise_uv.x * _Time.y, _Time.y * _noise_uv.y);
                float4 noiseTex = SAMPLE_TEXTURE2D(_noise, sampler_noise, TRANSFORM_TEX(noise_uv, _noise));

                float2 tex_uv = mul(i.uv + _noise_qiangdu * noiseTex.r - piv, tex_rot) + piv + float2(_tex_u * _Time.y, _Time.y * _tex_v);
                float4 mainTex = SAMPLE_TEXTURE2D(_Tex, sampler_Tex, TRANSFORM_TEX(tex_uv, _Tex));

                float mask_ang_rad = radians(_mask_ang);
                float2x2 mask_rot = float2x2(cos(mask_ang_rad), -sin(mask_ang_rad), sin(mask_ang_rad), cos(mask_ang_rad));
                float2 mask_uv = mul(i.uv - piv, mask_rot) + piv;
                float4 maskTex = SAMPLE_TEXTURE2D(_mask, sampler_mask, TRANSFORM_TEX(mask_uv, _mask));

                float autoValue = lerp(maskTex.a, saturate((pow(distance(i.uv, piv), _Power) * -3.333333 + 1.166667)), _Auto);

                float luminance = dot(mainTex.rgb, float3(0.3, 0.59, 0.11));
                float3 emissive = (_Color.rgb * luminance * i.color.rgb * autoValue * (mainTex.a * i.color.a * autoValue) * 8);

                float alpha = step(0.001, mainTex.a);
                float4 finalColor = float4(emissive, alpha);

                float3 gray = dot(finalColor.rgb, float3(0.299, 0.587, 0.114));
                finalColor.rgb = lerp(finalColor.rgb, gray.xxx, _GrayRange);

                return finalColor;
            }
            ENDHLSL
        }
    }
}
