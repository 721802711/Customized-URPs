Shader "URP/14_Transform"
{
    Properties
    {
        [KeywordEnum(Object,ObjectToHClip,ObjectToWorld, AbsoluteWS)] _pos ("Position Mode", Float) = 0
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
            float3 positionOS : TEXCOORD1;    // 物体空间位置
            float3 AbsoluteWorldSpacePosition : TEXCOORD2; // 绝对世界坐标
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
            
            #pragma multi_compile _POS_OBJECT _POS_OBJECTTOHCLIP _POS_OBJECTTOWORLD _POS_ABSOLUTEWS


            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;
                // 对象空间
                o.positionOS = v.positionOS;
                // 裁剪空间
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                // 世界空间
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                // 绝对世界坐标
                o.AbsoluteWorldSpacePosition = GetAbsolutePositionWS(o.positionWS);
                return o;
            }
 
            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {    
                
                // ===========================================================================================================
                // 场景颜色

                half4 col = half4(0,0,0,1);

                #if _POS_OBJECT

                    col.rgb = normalize(i.positionOS.xyz);
                #elif _POS_OBJECTTOHCLIP
                    col.rgb = normalize(i.positionCS.xyz);     
                #elif _POS_OBJECTTOWORLD
                    col.rgb = normalize(i.positionWS.xyz);
                #elif _POS_ABSOLUTEWS
                    col.rgb = normalize(i.AbsoluteWorldSpacePosition.xyz);

                #endif

                // ===========================================================================================================
                return col;
            }        
            ENDHLSL
        }
    }
}