Shader "B/13_3_Deacl"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("_BaseColor",Color) = (1,1,1,1)
        _EdgeStretchPrevent("_EdgeStretchPrevent",Range(-1,1)) = 0

        [KeywordEnum(alpha,Nome)] _Parallaxmap ("Parallaxmap Mode", Float) = 0

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent" "DisableBatch"="True" }


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float _EdgeStretchPrevent;
        float4 _BaseColor;
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

            float4 stexcoord : TEXCOORD1;       // 屏幕UV
            float4 cam2vertexRayOS : TEXCOORD2;  // 相机空间射线
            float3 cameraPosOS : TEXCOORD3;      // 相机空间下模型顶点位置
            half fogCoord: TEXCOORD4;          //输出雾效  
        };

        TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        TEXTURE2D(_CameraDepthTexture);               SAMPLER(sampler_CameraDepthTexture);

        ENDHLSL


        Pass
        {


            Blend[_SrcBlend][_DstBlend]
            ZTest LEqual
            ZWrite Off

            HLSLPROGRAM


            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _PARALLAXMAP_ALPHA  _PARALLAXMAP_NOME

            #pragma multi_compile_fog

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.stexcoord.xy = o.positionCS.xy * 0.5 + 0.5 * o.positionCS.w;     //计算出屏幕UV[0-1]
                #ifdef UNITY_UV_STARTS_AT_TOP                     //判断是否是OpenGL平台     
                o.stexcoord.y = o.positionCS.w - o.stexcoord.y;
                #endif
                o.stexcoord.zw = o.positionCS.zw;

                float4 posVS = mul(UNITY_MATRIX_V,mul(UNITY_MATRIX_M,v.positionOS));                              //相机空间下的模型顶点坐标    
                o.cam2vertexRayOS.w = -posVS.z;                                                                   //取相机空间的顶点坐标的z值的负数
                o.cam2vertexRayOS.xyz = mul(UNITY_MATRIX_I_M,mul(UNITY_MATRIX_I_V,float4(posVS.xyz,0))).xyz;      //相机空间转换到模型空间
                o.cameraPosOS = mul(UNITY_MATRIX_I_M,mul(UNITY_MATRIX_I_V,float4(0,0,0,1))).xyz;   

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                float2 SSuv = i.stexcoord.xy/i.stexcoord.w; 
                float SSDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,SSuv).x,_ZBufferParams);       //获取屏幕深度


                i.cam2vertexRayOS.xyz /= i.cam2vertexRayOS.w;                              //检测射线 透视除法
                float3 decalPos = i.cameraPosOS + i.cam2vertexRayOS.xyz * SSDepth;          //裁剪不需要的地方


                float2 YdecalUV = decalPos.xz + 0.5;                 

                //输出看一下效果    
                float mask = (abs(decalPos.x) < 0.5 ? 1:0)*(abs(decalPos.y) < 0.5 ? 1:0)*(abs(decalPos.z)<0.5?1:0);
                float3 decalNormal = normalize(cross(ddy(decalPos),ddx(decalPos))); 

                mask *= decalNormal.y > 0.5 * _EdgeStretchPrevent ? 1:0;

                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,YdecalUV);
                // 获取环境光
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);   



                float4 col = tex * _BaseColor;
                col.rgb *= MixFog(col,i.fogCoord) * ambient.rgb;
                col.a = 0;

                #if _PARALLAXMAP_ALPHA
                    col.a = tex.r * mask * _BaseColor.a;
                #elif _PARALLAXMAP_NOME
                    col.a = tex.a * mask * _BaseColor.a;
                #endif


                clip(col.a - 0.05);

                return col;
            }
            ENDHLSL
        }
    }
}