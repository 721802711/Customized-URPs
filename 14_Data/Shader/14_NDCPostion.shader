Shader "URP/14_NDCPostion"
{
    Properties
    {

    }
    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
        CBUFFER_START(UnityPerMaterial)
        CBUFFER_END


        struct appdata
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD1;
            float4 screenPos : TEXCOORD2;
        };


        SAMPLER(_CameraOpaqueTexture);                   //定义贴图
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent" "IgnoreProjector" = " True"}
        LOD 100

        Pass
        {
            Tags{ "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

                o.screenPos = ComputeScreenPos(o.positionCS);                      // 计算屏幕坐标

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                float2 NDCPosition = (i.positionCS.xy / _ScreenParams.xy);

                float4 ndcPos;

                ndcPos.xy = NDCPosition;
                ndcPos.zw = float2(0,1);

                //return i.screenPos;

                return ndcPos;
            }
            ENDHLSL
        }
    }
}