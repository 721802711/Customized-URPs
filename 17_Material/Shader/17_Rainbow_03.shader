Shader "B/17_Rainbow_03"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // 镭射相关属性（可根据需要调节）
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _HueTint("Hue Tint Color", Color) = (1,1,1,1)
        _Intensity("Intensity", Range(0,8)) = 1.5
        _FresnelPower("Fresnel Power", Range(0.1,16)) = 4.0
        _RotateAngle("Rotate Angle (deg)", Range(0,360)) = 45
        _RotateAxis("Rotate Axis (XYZ)", Vector) = (0,0,1,0)
        _LightDir("Light Direction (world)", Vector) = (0,0,1,0)
        _BandContrast("Band Contrast", Range(0,8)) = 6.0
        _BandOffset("Band Offset", Range(-1,1)) = 0.0
        _HueShift("Hue Shift", Range(-1,1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;

        // 镭射 Shader 对应的参数
        float4 _BaseColor;
        float4 _HueTint;
        float _Intensity;
        float _FresnelPower;
        float _RotateAngle;
        float4 _RotateAxis;
        float4 _LightDir;
        float _BandContrast;
        float _BandOffset;
        float _HueShift;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float4 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 worldPos : TEXCOORD1;
            float3 worldNormal : TEXCOORD2;
        };

        TEXTURE2D(_MainTex); 
        SAMPLER(sampler_MainTex);

        // 旋转工具函数
        float3 RotateAroundAxis(float3 v, float3 axis, float angle)
        {
            float c = cos(angle);
            float s = sin(angle);
            return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1 - c);
        }

        // Hue → RGB
        float3 HueToRGB(float h)
        {
            float3 col;
            float3 p = abs(frac(h + float3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
            col = saturate(p - 1.0);
            return col;
        }

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                // 提供世界坐标 & 法线（简易方式，用 object->world 乘 normal）
                o.worldPos = mul(unity_ObjectToWorld, v.positionOS).xyz;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.worldNormal = NormalInputs.normalWS;                                //  获取世界空间下法线信息


                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 1. 原本 MainTex 取样保留
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                
                // 2. 获取世界法线与视角方向
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Fresnel
                float fres = 1.0 - saturate(dot(N, V));
                fres = pow(fres, max(0.0001, _FresnelPower));

                // 旋转法线
                float3 axis = normalize(_RotateAxis.xyz == float3(0,0,0) ? float3(0,0,1) : _RotateAxis.xyz);
                float rad = radians(_RotateAngle);
                float3 rotated = RotateAroundAxis(N, axis, rad);

                // hue 计算
                float hue = atan2(rotated.y, rotated.x) / (2.0 * 3.14159) + 0.5 + _HueShift;
                hue = frac(hue);
                float3 hueRGB = HueToRGB(hue);

                // 光带 band
                float3 Ldir = normalize(_LightDir.xyz);
                float3 addNL = normalize(N + Ldir);
                float dotNL = saturate(dot(addNL, V));
                float band = pow(saturate(dotNL * _BandContrast + _BandOffset), 1.0);

                // 混色
                float3 hueTinted = hueRGB * _HueTint.rgb;
                float3 laserColor = hueTinted * fres * band * _Intensity;

                //  用 fresnel 做 Lerp（保持 MainTex 为底）
                float t = saturate(fres);
                float3 finalRGB = lerp(baseCol.rgb, laserColor, t);

                return half4(finalRGB, baseCol.a);
            }

            ENDHLSL
        }
    }
}
