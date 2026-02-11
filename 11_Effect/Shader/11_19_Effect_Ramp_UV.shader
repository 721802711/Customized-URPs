Shader "Custom/Effect_Ramp_UV"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _RampTex("Ramp Texture", 2D) = "white" {}
        _RampIntensity("Ramp Intensity", Range(0, 1)) = 1
        _BaseColor("Base Color", Color) = (1, 1, 1, 1) 

        [KeywordEnum(UV, Luminance)] _RampMode("Ramp Mode", Float) = 0

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


            #pragma multi_compile _RAMP_MODE_UV _RAMP_MODE_LUMINANCE

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

            fixed4 frag(v2f i) : SV_Target
            {
                // 基础颜色贴图
                fixed4 baseCol = tex2D(_MainTex, i.uv) * _BaseColor;


                // 使用Y轴 UV 采样 Ramp
                float rampUV = saturate(i.uv.y);
                fixed4 rampCol = tex2D(_RampTex, float2(rampUV, 0.5));

                // 混合Ramp效果
                fixed4 finalCol = lerp(baseCol, rampCol * baseCol, _RampIntensity);

                return finalCol;
            }
            ENDCG
        }
    }
    FallBack "Unlit/Transparent"
}
