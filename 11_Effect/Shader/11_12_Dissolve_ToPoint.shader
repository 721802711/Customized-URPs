Shader "B/11_12_Dissolve_ToPoint"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
        [Space(20)]
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _StartPoint("Start Point",Vector) = (1,1,1,1)   //需要找到该点的世界坐标
        _MaxDistance("Max Distance",Float) = 0
        _DistanceEffect("Distance Effect",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Cull Off
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _NoiseTex_ST;
            half _Threshold;
            float _EdgeLength;
            float4 _RampTex_ST;
            float4 _StartPoint;
            float _MaxDistance;
            half _DistanceEffect;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS:POSITION;
                float2 texcoord:TEXCOORD;
                float4 vertexColor : COLOR;
                float4 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float4 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float3 normalWS: TEXCOORD2;
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
                o.positionWS = PositionInputs.positionWS;   

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                o.vertexColor = v.vertexColor;
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float distance = length(i.positionWS - _StartPoint.xyz);
                float normalizedDistance = 1.0 - saturate(distance / _MaxDistance);

                float cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                clip(cutout - _Threshold);
                

                float degree = saturate((cutout - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                float3 normalWS = normalize(i.normalWS);


                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);

                half3 diffuseColor = mainLight.color.rgb * albedo.rgb * saturate(dot(normalWS,lightDirWS));
                
                half4 finalColor = lerp(edgeColor, half4(diffuseColor,1.0), degree);

                return half4(finalColor.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}