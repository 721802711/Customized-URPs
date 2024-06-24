Shader "B/11_11_Dissolve_DirectionAsh"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        [NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "white" { }
        [NoScaleOffset] _RampTex ("Ramp Tex", 2D) = "white" { }

        [Space(20)]
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
        _MinBorderY("Min Border Y",Float) = 0
        _MaxBorderY("Max Border Y",Float) = 0
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
        [Space(20)]
        [NoScaleOffset]_WhiteNoiseTex("White Noise Tex",2D) = "white" {}
        _AshColor("Ash Color",Color) = (1,1,1,1)
        _AshWidth("Ash Width",range(0.0,0.25)) = 0
        _AshDensity("Ash Density", Range(0, 1)) = 1
        _FlyIntensity("Fly Intensity", Range(0,0.3)) = 0.1
		_FlyDirection("Fly Direction", Vector) = (1,1,1,1) 
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
            half _Threshold;
            float _EdgeLength;
            float _MinBorderY;
            float _MaxBorderY;
            half _DistanceEffect;
            half4 _AshColor;
            float _AshWidth;
            float _AshDensity;
            float _FlyIntensity;
            float4 _FlyDirection;
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
                float2 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_WhiteNoiseTex);  SAMPLER(sampler_WhiteNoiseTex);
            TEXTURE2D(_RampTex);    SAMPLER(sampler_RampTex);

        ENDHLSL

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float GetNormalizeDistance(float posY)
            {
                float range = _MaxBorderY - _MinBorderY;
                float border = _MaxBorderY;

                float distance = abs(posY - border);
                return saturate(distance / range);
            }

            v2f vert (appdata v)
            {
                v2f o;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                float cutout = GetNormalizeDistance(o.positionWS.y);
                float3 localFlyDirection = TransformWorldToObjectDir(_FlyDirection.xyz);
                float flyDegree = (_Threshold- cutout) / _EdgeLength;
                float val = saturate(flyDegree * _FlyIntensity);
                v.positionOS.xyz += localFlyDirection * val;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   


                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.vertexColor = v.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float commonNoise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv).r;
                float whiteNoise = SAMPLE_TEXTURE2D(_WhiteNoiseTex,sampler_WhiteNoiseTex,i.uv).r;

                float normalizedDistance = GetNormalizeDistance(i.positionWS.y);
                float cutout = commonNoise * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                float edgeCutout = cutout - _Threshold;
                clip(edgeCutout + _AshWidth);

                float degree = saturate(edgeCutout / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));
                
                half4 finalColor = lerp(edgeColor, albedo, degree);
                if(degree < 0.001)
                {
                    clip(whiteNoise * _AshDensity + normalizedDistance * _DistanceEffect - _Threshold);
                    finalColor = _AshColor;
                }

                return half4(finalColor.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}