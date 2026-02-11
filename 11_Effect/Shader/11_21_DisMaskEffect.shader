Shader "B/11_21_DisMaskEffect"
{
    Properties
    {
        _DisTex("Dis Texture", 2D) = "white" {}
        _MaskTex("Mask Texture", 2D) = "white" {}

        _DisParameter("Dis Parameter", Vector) = (1,1,1,1)
        _MaskParameter("Mask Parameter", Vector) = (1,1,1,1)
        // xy: 方向, z: 旋转角度, w: 透明度
        // 扭曲强度
        _DisStrength("Dis Strength", Range(0,10)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent-1" }
        Pass
        {

            Cull Off
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha



            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                float4 vertexColor  : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 screenPos   : TEXCOORD1;
                float4 vertexColor  : COLOR;
            };

        CBUFFER_START(UnityPerMaterial)
            float4 _DisParameter;
            float4 _MaskParameter;
            float _DisStrength;
        CBUFFER_END


            TEXTURE2D(_DisTex);
            SAMPLER(sampler_DisTex);

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.vertexColor = v.vertexColor;
                o.screenPos = ComputeScreenPos(o.positionHCS);
                return o;
            }

            float2 RotateUV(float2 uv, float2 center, float Rotation)
            {
                float rad = Rotation * (3.1415926 / 180.0);
                
                // 平移到旋转中心
                uv -= center;
                float s = sin(rad); 
                float c = cos(rad);






                // 旋转
                float2x2 rot = float2x2(c, -s, s, c);
                rot *= 0.5;
                rot += 0.5;
                rot = rot * 2.0 - 1.0;


                uv.xy = mul(uv.xy, rot);
                uv += center;

                return uv;
            }


            half4 frag(Varyings i) : SV_Target
            {

                float t = _Time.y; // 时间

                // ==== DisTex UV ====
                float2 disDir = _DisParameter.xy;

                float4 vertexColor = i.vertexColor.a * _MaskParameter.w;

                float2 disUV =  disDir * t;
                float2 RotateUVCenter = RotateUV(i.uv, float2(0.5,0.5), _DisParameter.z);  

                half4 disSample = SAMPLE_TEXTURE2D(_DisTex, sampler_DisTex, disUV + RotateUVCenter);

                // ==== MaskTex UV ====

                float2 maskDir = _MaskParameter.xy;
                float2 maskUV = maskDir * t;
                float2 RotateMaskUVCenter = RotateUV(i.uv, float2(0.5,0.5), _MaskParameter.z);

                half4 maskSample = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskUV + RotateMaskUVCenter);


                // ==== Screen UV ====
                float2 screenUV = i.screenPos.xy / i.screenPos.w ;
                screenUV += maskSample * disSample * 0.01 * _DisStrength; // 扭曲强度

                // Sample screen
                half4 screenCol = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

                return screenCol;

            }
            ENDHLSL
        }
    }
}
