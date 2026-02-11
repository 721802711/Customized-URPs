Shader "B/10_07_UnlitFresnel"
{
    Properties
    {
        _MainTex        ("Texture", 2D) = "white" {}
        _BaseColor      ("Base Color", Color) = (1,1,1,1)

        [HDR]_FresnelColor   ("Fresnel Color", Color) = (1,1,1,1)
        _Fresnel_Fade   ("Fresnel Fade", Range(0,10)) = 1
        _Fresnel_Intensity ("Fresnel Intensity", Range(0,3)) = 1

        [Toggle] _UseFresnel ("Enable Fresnel", Float) = 1
        [Toggle] _FresnelInverse ("Inverse Fresnel", Float) = 0
        [Enum(Add,0,Multiply,1)] _FresnelBlendMode ("Fresnel Blend Mode", Float) = 0

        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0,2)) = 1

        _MainTex_Speed ("MainTex UV Speed (X,Y)", Vector) = (0,0,0,0)
        _BumpMap_Speed ("BumpMap UV Speed (X,Y)", Vector) = (0,0,0,0)

        [Toggle] _ZWrite ("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline"}

        Pass
        {
            ZWrite [_ZWrite]
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;  
                half3  normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 texcoord   : TEXCOORD0;
                float4 color      : COLOR;        // ✅ 顶点颜色
            };
 
            struct Varyings
            {  
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 uv         : TEXCOORD1;

                float3 normalWS   : TEXCOORD2;
                float3 tangentWS  : TEXCOORD3;
                float3 bitangentWS: TEXCOORD4;

                float4 color      : COLOR;       // ✅ 顶点颜色传递
            };
 
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _BumpMap_ST;
                float4 _BaseColor;
                float4 _FresnelColor;
                half   _Fresnel_Fade;
                half   _Fresnel_Intensity;
                half   _UseFresnel;
                half   _FresnelInverse;
                half   _BumpScale;
                float4 _MainTex_Speed;
                float4 _BumpMap_Speed;
                half   _FresnelBlendMode;
            CBUFFER_END
 
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);    SAMPLER(sampler_BumpMap);

            Varyings vert (Attributes v)
            {
                Varyings o;

                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = posInputs.positionCS; 
                o.positionWS = posInputs.positionWS;  

                // UV 流动
                float2 uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
                uvMain += _MainTex_Speed.xy * _Time.y;
                o.uv.xy = uvMain;

                float2 uvBump = TRANSFORM_TEX(v.texcoord, _BumpMap);
                uvBump += _BumpMap_Speed.xy * _Time.y;
                o.uv.zw = uvBump;

                // World normal / tangent / bitangent
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS    = normalInputs.normalWS;
                o.tangentWS   = normalInputs.tangentWS;
                o.bitangentWS = normalInputs.bitangentWS;

                o.color = v.color; // ✅ 顶点色传递

                return o;
            }
 
            half4 frag (Varyings i) : SV_Target
            {
                // ======================
                // 法线
                // ======================
                half3 tangentNormal = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv.zw), _BumpScale);
                float3x3 TBN = float3x3(normalize(i.tangentWS), normalize(i.bitangentWS), normalize(i.normalWS));
                half3 N = normalize(mul(tangentNormal, TBN));

                half3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                half dotNV = saturate(dot(N, V));

                // ======================
                // Fresnel term
                // ======================
                half fresnelTerm = (_FresnelInverse > 0.5) 
                    ? pow(dotNV, _Fresnel_Fade) * _Fresnel_Intensity 
                    : pow(1.0 - dotNV, _Fresnel_Fade) * _Fresnel_Intensity;

                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * _BaseColor;

                // 顶点颜色叠加（颜色和Alpha）
                texColor *= i.color;

                if (_UseFresnel > 0.5)
                {
                    if (_FresnelBlendMode < 0.5)
                        texColor.rgb += fresnelTerm * _FresnelColor.rgb; // ADD
                    else
                        texColor.rgb *= fresnelTerm * _FresnelColor.rgb; // MULTIPLY
                }

                return texColor;
            }
            ENDHLSL
        }
    }
}
