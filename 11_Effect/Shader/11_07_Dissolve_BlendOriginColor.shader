Shader "B/11_07_Dissolve_BlendOriginColor"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }

        [Space(20)]
        [HDR]_EdgeFirstColor ("First Edge Color", Color) = (1, 1, 1, 1)
        _EdgeSecondColor ("Second Edge Color", Color) = (1, 1, 1, 1)
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Cull Off
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            half _Threshold;
            float _EdgeLength;
            float4 _EdgeFirstColor, _EdgeSecondColor;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS:POSITION;
                float2 texcoord:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float4 uv:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);

        ENDHLSL

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                o.vertexColor = v.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r;
                clip(cutout - _Threshold);

                float degree = saturate((cutout - _Threshold) / _EdgeLength);
                half4 edgeColor = lerp(_EdgeFirstColor, _EdgeSecondColor, degree);
                        
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                half4 finalColor = lerp(edgeColor, col, degree);
                return half4(finalColor.rgb, degree);
            }
            ENDHLSL
        }
    }
}