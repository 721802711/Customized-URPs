Shader "Foundation/Base/Keyword"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint Color", Color) = (1,1,1,1)
        
        // 枚举关键字：生成多个互斥选项
        [KeywordEnum(None, Green, Red)] _BlendMode ("混合模式", Float) = 0
        
        // 开关关键字：生成开/关两个状态
        [Toggle] _EnableEffect ("启用效果", Float) = 0
        
        // 自定义关键字名称
        [Toggle(CUSTOM_FEATURE)] _CustomFeature ("自定义功能", Float) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _Color;
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
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // KeywordEnum 
            #pragma multi_compile _BLENDMODE_NONE _BLENDMODE_GREEN _BLENDMODE_RED
            
            // Toggle 
            #pragma shader_feature _ENABLEEFFECT_ON
            
            // Toggle(CUSTOM_FEATURE) 使用自定义名称
            #pragma shader_feature CUSTOM_FEATURE


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 col = baseCol * _Color;

                // KeywordEnum 示例：混合模式
                #if _BLENDMODE_GREEN
                    col.rgb = half3(0.0, 1.0, 0.0) ;
                #elif _BLENDMODE_RED
                    col.rgb = half3(1.0, 0.0, 0.0) ;
                #endif
                // _BLENDMODE_NONE 不做处理

                // Toggle 示例：启用效果
                #ifdef _ENABLEEFFECT_ON
                    col.rgb = lerp(col.rgb, 1.0 - col.rgb, 0.3);
                #endif

                // 自定义关键字示例
                #ifdef CUSTOM_FEATURE
                    col.rgb *= float3(1, 0.5, 0.5);
                #endif

                return col;
            }
            ENDHLSL
        }
    }
}