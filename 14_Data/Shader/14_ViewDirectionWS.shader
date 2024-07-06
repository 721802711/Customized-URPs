Shader "URP/14_ViewDirectionWS"
{
    Properties
    {

    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  


        CBUFFER_START(UnityPerMaterial)

        CBUFFER_END

       
        // 顶点着色器的输入
        struct a2v
        {
            float4 positionOS : POSITION; // 物体空间顶点位置
            float3 normalOS : NORMAL;     // 物体空间法线
            float2 texcoord : TEXCOORD0;  // 纹理坐标
            float4 tangentOS : TANGENT;   // 物体空间切线
        };
        
        // 顶点着色器的输出
        struct v2f
        {
            float4 positionCS : SV_POSITION;  // 裁剪空间位置
            float3 positionWS : TEXCOORD0;    // 世界空间位置
            float3 normalWS : TEXCOORD1;      // 世界空间法线
            float3 tangentWS : TEXCOORD2;     // 世界空间切线
            float3 bitangentWS : TEXCOORD3;   // 世界空间副切线
            float3 viewDirectionWS : TEXCOORD4; // 世界空间视角方向
            float2 uv : TEXCOORD5;            // 纹理坐标
            float4 screenPos : TEXCOORD6;     // 屏幕坐标位置

        };

        ENDHLSL

        Pass
        {
            Name "Pass"
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }

            //Blend SrcAlpha OneMinusSrcAlpha

 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            


            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                // 顶点动画
                o.uv = v.texcoord;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                                              //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;

                o.viewDirectionWS = GetWorldSpaceNormalizeViewDir(o.positionWS);    // 世界空间视角方向

                o.screenPos = ComputeScreenPos(o.positionCS);                      // 计算屏幕坐标
                return o;
            }
 
            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {    
                
                // ===========================================================================================================
                // 世界空间视角方向

                half3 viewDirectionWS = normalize(i.viewDirectionWS);


                // ===========================================================================================================


                half4 col = half4(0,0,0,0);


                col.rgb = viewDirectionWS;
                col.a = 1;

                return col;
            }        
            ENDHLSL
        }
    }
}