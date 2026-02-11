Shader "B/EdgeIntersectionFresnel"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}
        [HDR]_BaseColor("Base Color", Color) = (1,1,1,1)

        _DepthOffset("Depth Offset", Float) = 1
        _DepthEdgeSize("Depth Edge Size", Range(0,0.01)) = 0.005

        [HDR]_EdgeColor("Edge Color", Color) = (0,1,1,1)

        _Emiss("Fresnel Intensity", Float) = 1
        _RimPower("Rim Power", Float) = 2

        _UVSpeedX("UV Speed X", Float) = 0.1
        _UVSpeedY("UV Speed Y", Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass
        {
            Name "ForwardEdge"
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4  _BaseColor;

                float  _DepthOffset;
                float  _DepthEdgeSize;
                float4 _EdgeColor;

                float  _Emiss;
                float  _RimPower;

                float  _UVSpeedX;
                float  _UVSpeedY;
            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 texcoord   : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS);
                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
                o.normalWS = normalInputs.normalWS;

                // UV + 流动偏移
                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                uv += float2(_UVSpeedX, _UVSpeedY) * _Time.y;
                o.uv = uv;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // 主贴图采样
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;

                // ======================
                // 深度差：物体和场景的相交部分
                // ======================
                float2 screenUV = (i.positionCS.xy / i.positionCS.w) * 0.5 + 0.5;

                // 场景深度
                float sceneRawDepth = SampleSceneDepth(screenUV);
                float sceneDepth01  = Linear01Depth(sceneRawDepth, _ZBufferParams);

                // 当前像素深度
                float pixelDepth01  = Linear01Depth(i.positionCS.z / i.positionCS.w, _ZBufferParams);

                // 计算深度差
                float depthDiff = saturate((sceneDepth01 - pixelDepth01 + _DepthEdgeSize) * (100 * _DepthOffset));

                // ======================
                // Fresnel Rim
                // ======================
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float NdotV = saturate(dot(normalize(i.normalWS), V));
                float fresnel = pow(1.0 - NdotV, _RimPower) * _Emiss;

                // ======================
                // 叠加效果
                // ======================
                float edgeFactor = saturate(depthDiff + fresnel);
                half3 finalCol = lerp(baseCol.rgb, _EdgeColor.rgb, edgeFactor);

                return half4(finalCol, edgeFactor);
            }
            ENDHLSL
        }
    }
}
