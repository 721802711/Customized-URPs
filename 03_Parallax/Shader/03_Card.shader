Shader "B/03_Card"
{
    Properties
    {
        _MainTex ("FrameTex", 2D) = "white" {}

        [Space(20)]
        _CardTex1 ("_CardTex1", 2D) = "white" {}
        _ParallaxDeoth1 ("_depth", Float) = -0.1


        [Space(20)]
        _CardTex3 ("_CardTex3", 2D) = "white" {}
        _ParallaxDeoth3 ("_depth3", Float) = -0.2


        [Space(20)]
        _CardTex4 ("_CardTex4", 2D) = "white" {}
        _ParallaxDeoth4 ("_depth4", Float) = -0.3


        [Space(20)]
        _CardTex2 ("_CardTex2", 2D) = "white" {}
        _ParallaxDeoth2 ("_depth2", Float) = -0.5
        _FlowVector2AndSpeed("_FlowVector2AndSpeed", Vector) = (1,1,0,0)


        [Space(20)]      
        _BackTex ("_BackTex", 2D) = "white" {}  

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
        LOD 100
        Cull Off

        Blend SrcAlpha OneMinusSrcAlpha

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _BackTex_ST;
        float4 _CardTex1_ST, _CardTex2_ST;
        float4 _FlowVector2AndSpeed;
        float _ParallaxDeoth1, _ParallaxDeoth3, _ParallaxDeoth4;
        float _ParallaxDeoth2;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 tangentWS : TEXCOORD1;
                float3 bitangentWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
                float4 vertexColor : TEXCOORD5;
                float3 viewDirWS: TEXCOORD6;                                       //输出视角方向
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
            TEXTURE2D(_CardTex1);                          SAMPLER(sampler_CardTex1);
            TEXTURE2D(_CardTex2);                          SAMPLER(sampler_CardTex2);
            TEXTURE2D(_CardTex3);                          SAMPLER(sampler_CardTex3);
            TEXTURE2D(_CardTex4);                          SAMPLER(sampler_CardTex4);
            TEXTURE2D(_BackTex);                          SAMPLER(sampler_BackTex);

        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float2 CalculateRealUVAfterDepth(float2 uv, float3 viewDirTS, float depth)
            {
                // 计算视角方向和深度法线的夹角
                float cosTheta = dot(normalize(viewDirTS), float3(0, 0, 1));
                // 根据深度差计算出两点间的距离
                float dis = depth / cosTheta;
                // 计算出应用深度后对应的uv 
                float3 originUVPoint = float3(uv, 0);
                float3 afterDepth = originUVPoint + normalize(viewDirTS) * dis;
                // 返回应用深度后的uv
                return afterDepth.xy;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);                                    //xy分量，储存颜色贴图uv
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取齐次空间位置


                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS = NormalInputs.tangentWS;
                o.bitangentWS = NormalInputs.bitangentWS;
                o.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;   //  相机世界位置 - 世界空间顶点位置
                o.vertexColor = v.vertexColor;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                float3 tangentWS      = normalize(i.tangentWS);
                float3 normalWS       = normalize(i.normalWS);
                float3 bitangentWS    = normalize(i.bitangentWS);


                float3 viewDirWS      = normalize(i.viewDirWS); 
                
                Light mylight         = GetMainLight();                                //获取场景主光源
                half3 LightDir        = normalize(mylight.direction);                 //获取光照方向



                // 正面
                float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);
                float3 viewDirTS = mul(TBN, viewDirWS);        // 视角方向转换到切线空间

                // 计算深度值影响过后的UV 
                float2 uv1AfterDepth = CalculateRealUVAfterDepth(i.uv, viewDirTS, _ParallaxDeoth1);
                float2 uv2AfterDepth = CalculateRealUVAfterDepth(i.uv, viewDirTS, _ParallaxDeoth2);
                float2 uv3AfterDepth = CalculateRealUVAfterDepth(i.uv, viewDirTS, _ParallaxDeoth3);
                float2 uv4AfterDepth = CalculateRealUVAfterDepth(i.uv, viewDirTS, _ParallaxDeoth4);

                // 采样视差贴图
                uv1AfterDepth = saturate(uv1AfterDepth);
                float4 _ParallaxTex1 = SAMPLE_TEXTURE2D(_CardTex1, sampler_CardTex1, uv1AfterDepth * _CardTex1_ST.xy + _CardTex1_ST.zw);

                // 采样视差贴图
                uv3AfterDepth = saturate(uv3AfterDepth);
                float4 _ParallaxTex3 = SAMPLE_TEXTURE2D(_CardTex3, sampler_CardTex3, uv3AfterDepth);

                // 采样视差贴图
                uv4AfterDepth = saturate(uv4AfterDepth);
                float4 _ParallaxTex4 = SAMPLE_TEXTURE2D(_CardTex4, sampler_CardTex4, uv4AfterDepth);

                uv2AfterDepth += - _FlowVector2AndSpeed.xy * _FlowVector2AndSpeed.z * _Time.y; 
                float4 _ParallaxTex2 = SAMPLE_TEXTURE2D(_CardTex2, sampler_CardTex2, uv2AfterDepth * _CardTex2_ST.xy + _CardTex2_ST.zw);

                // 采样边框
                float4 _FrameTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw);

                // 采样背面贴图
                half4 BackTex = SAMPLE_TEXTURE2D(_BackTex,sampler_BackTex,i.uv * _BackTex_ST.xy + _BackTex_ST.zw);     //贴图采样变成3个变量

                float4 finalColor = float4(0,0,0,0);


                if (dot(viewDirWS, normalWS) > 0)            // 如果视角和法线的点积大于0，说明是正面
                {
                    finalColor = _ParallaxTex2; 
                    finalColor = lerp(finalColor, _ParallaxTex1, _ParallaxTex1.a);
                    finalColor = lerp(finalColor, _ParallaxTex3, _ParallaxTex3.a);
                    finalColor = lerp(finalColor, _ParallaxTex4, _ParallaxTex4.a);
                    finalColor = lerp(finalColor, _ParallaxTex3, _ParallaxTex3.a);
                    finalColor = lerp(finalColor, _ParallaxTex1, _ParallaxTex1.a);
                    finalColor = lerp(finalColor, _FrameTex, _FrameTex.a);
                    finalColor.a = BackTex.a;
                }
                else                                         // 如果视角和法线的点积小于0，说明是背面
                {
                    finalColor = BackTex;
                }
                

                return finalColor;
            }
            ENDHLSL
        }
    }
}