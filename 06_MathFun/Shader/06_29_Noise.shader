Shader "B/06_29_Noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}


        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _cull ("cull Mode", Float) = 0 
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}

        LOD 100


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
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

            Blend[_SrcBlend][_DstBlend]
            Cull[_cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float Random2(float2 st)
            {
                st = float2( dot(st,float2(127.1,311.7)), dot(st,float2(269.5,183.3)) );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }



            float noise (float2 st) 
            {
                float2 i = floor(st);
                float2 f = frac(st);


                float2 u = f * f * (3.0 - 2.0 * f);
                
                return lerp( lerp( dot( Random2(i + float2(0.0,0.0) ), f - float2(0.0,0.0) ),
                     dot( Random2(i + float2(1.0,0.0) ), f - float2(1.0,0.0) ), u.x),
                    lerp( dot( Random2(i + float2(0.0,1.0) ), f - float2(0.0,1.0) ),
                     dot( Random2(i + float2(1.0,1.0) ), f - float2(1.0,1.0) ), u.x), u.y);
            }


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;   
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {

                half4 col = float4(0.0,0.0,0.0,0.0);
                float2 uv = i.uv;


                // some noise in action
                float2 pos = float2(uv * 10.0);

                // Use the noise function
                col.rgb =  noise(pos) * 0.5 + 0.5;

                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}