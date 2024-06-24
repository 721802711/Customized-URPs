Shader "B/11_10_Dissolve_FromDirectionX"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1


        [Space(20)]
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _Direction ("Direction", Int) = 1 //1表示从X正方向开始，其他值则从负方向
        _MinBorderX ("Min Border X", Float) = -0.5 //从程序传入
        _MaxBorderX ("Max Border X", Float) = 0.5  //从程序传入
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Cull Off
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _NoiseTex_ST, _RampTex_ST;
            half _Threshold;
            float _EdgeLength;
            int _Direction;
            float _MinBorderX;
            float _MaxBorderX;
            half _DistanceEffect;
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
                float objPosX: TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);    SAMPLER(sampler_RampTex);

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

                o.objPosX = v.positionOS.x;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {


                float range = _MaxBorderX - _MinBorderX;
                float border = _MinBorderX;
                if (_Direction == 1) //1表示从X正方向开始，其他值则从负方向
                    border = _MaxBorderX;

                float distance = abs(i.objPosX - border);
                float normalizedDistance = saturate(distance / range);


                float cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                clip(cutout - _Threshold);

                float degree = saturate((cutout - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                
                half4 finalColor = lerp(edgeColor, col, degree);

                return half4(finalColor.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}