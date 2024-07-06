Shader "URP/14_SceneColor"
{
    Properties
    {
        [KeywordEnum(positionCS,screenPos)] _position ("Position Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  


        CBUFFER_START(UnityPerMaterial)

        CBUFFER_END

        SAMPLER(_CameraOpaqueTexture);                   //定义贴图
       
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
            float4 screenPos : TEXCOORD1;     // 屏幕坐标位置
        };

        ENDHLSL

        Pass
        {
            Name "Pass"
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }

 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _POSITION_POSITIONCS _POSITION_SCREENPOS

            float4 ScreenColor(float2 uv)                                               //获取屏幕颜色
            {
                return tex2D(_CameraOpaqueTexture,  uv);
            }

            float4 ComputeScreenPos(float4 pos, float projectionSign)                          //齐次坐标变换到屏幕坐标
            {
                float4 o = pos * 0.5f;
                o.xy = float2(o.x,o.y * projectionSign) + o.w;             
                o.zw = pos.zw;
                return o;
			}

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置
                o.positionWS = PositionInputs.positionWS;                                              //获取世界空间位置信息


                o.screenPos = ComputeScreenPos(o.positionCS);                      // 计算屏幕坐标  

                return o;
            }
 
            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {    
                
                // ===========================================================================================================
                // 场景颜色

                half4 col = half4(0,0,0,1);

                #if _POSITION_POSITIONCS
                    // 使用 positionCS 裁剪空间位置计算屏幕颜色
                    half2 screenUV = (i.positionCS.xy / _ScreenParams.xy);
                    col = tex2D(_CameraOpaqueTexture, screenUV);
                #elif _POSITION_SCREENPOS
                    // 使用 screenPos 屏幕坐标计算屏幕颜色
                    col = ScreenColor(i.screenPos.xy / i.screenPos.w);     
                #endif

                // ===========================================================================================================
                return col;
            }        
            ENDHLSL
        }
    }
}