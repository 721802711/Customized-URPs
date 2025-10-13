Shader "B/11_19_Effect_Ramp_Luminance"
{
    Properties
    {
        _MainTex("Main Texture (Gray Source)", 2D) = "white" {}
        _RampTex("Ramp Texture", 2D) = "white" {}
        _RampIntensity("Ramp Intensity", Range(0, 1)) = 1
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _RampTex;
            float4 _BaseColor;
            float _RampIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 灰度计算函数（感知亮度）
            float GetLuminance(fixed3 color)
            {
                return dot(color, fixed3(0.299, 0.587, 0.114));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 主贴图颜色（通常为灰度图）
                fixed4 mainCol = tex2D(_MainTex, i.uv) * _BaseColor;

                // 计算主贴图灰度作为 Ramp 的采样坐标
                float luminance = saturate(GetLuminance(mainCol.rgb));

                // 采样 Ramp
                fixed4 rampCol = tex2D(_RampTex, float2(luminance, 0.5));

                // Ramp 颜色混合主贴图
                fixed4 finalCol = lerp(mainCol, rampCol, _RampIntensity);
                finalCol.a = mainCol.a;

                return finalCol;
            }
            ENDCG
        }
    }
}
