Shader "B/06_27_Patterns"
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

            float Random(float2 st)
            {

                return frac(sin(dot(st.xy, float2(12.9898, 78.233)))* 43758.5453123);
            }

            float2 TruchetPattern(float2 _st, float _index)
            {
                _index = frac(((_index-0.5)*2.0));

                if (_index > 0.75)
                {
                    _st = 1.0 - _st;
                }
                else if (_index > 0.5)
                {
                    _st = float2(1.0 -_st.x,_st.y);
                }
                else if (_index > 0.25) 
                {
                    _st = 1.0 - float2(1.0 - _st.x,_st.y);
                }
                return _st;
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
                uv *= 10;

                float2 ipos = floor(uv);  // get the integer coords
                float2 fpos = frac(uv);  // get the fractional coords

                float2 tile = TruchetPattern(fpos, Random(ipos));

                // Assign a random value based on the integer coord
                col.rgb = smoothstep(tile.x - 0.3,tile.x,tile.y) - smoothstep(tile.x,tile.x + 0.3,tile.y);

                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}