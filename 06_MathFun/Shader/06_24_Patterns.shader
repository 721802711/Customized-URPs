Shader "B/06_24_Patterns"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tile ("_Tile", Int) = 2
        _Size ("Size", Range(0 , 1)) = 1

        [Space(20)]
        [KeywordEnum(Rotate, Tile, Time, UV2, PITime)] _Dir ("Anim Direction", float) = 0
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
            float _Tile, _Size;
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

            #pragma multi_compile _ _DIR_ROTATE _DIR_TILE _DIR_TIME _DIR_UV2 _DIR_PITIME


            float2 rotate2D(float2 _st, float _angle)
            {
                // 将ST坐标移动到原点附近
                _st -= 0.5;
                
                // 创建一个2x2旋转矩阵
                float2x2 rotationMatrix = float2x2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
                // 应用旋转矩阵
                _st = mul(rotationMatrix, _st);
                
                // 将ST坐标移回原来的位置
                _st += 0.5;

                return _st;
            }


            float2 Tile(float2 _st, float _zoom)
            {
                _st *= _zoom;
                return frac(_st);
            }


            float Box(float2 _st, float2 _size, float _smoothEdges)
            {
                // 计算盒子的中心点和半尺寸
                _size = 0.5 - _size * 0.5;
                float2 aa = _smoothEdges * 0.5; // 为 X 和 Y 分量分别计算平滑边缘

                float2 uv = smoothstep(_size,_size + aa, _st);
                // 使用 smoothstep 创建平滑边缘效果
                 uv *= smoothstep(_size, _size + aa,  1.0 - _st);

                // 返回两个方向上的过渡效果相乘的结果
                return uv.x * uv.y;
            }


            float2 BrickTile(float2 _st, float _zoom)
            {
                _st *= _zoom;

                _st.x += step(1.0, fmod(_st.y, 2.0)) * 0.5;

                return frac(_st);
            }

            float2 RotateTilePattern(float2 _st)
            {
                //  Scale the coordinate system by 2x2
                _st *= 2.0;

                //  Give each cell an index number
                //  according to its position
                float index = 0.0;
                index += step(1.0, fmod(_st.x,2.0));
                index += step(1.0, fmod(_st.y,2.0)) * 2.0;


                    //      |
                    //  2   |   3
                    //      |
                    //--------------
                    //      |
                    //  0   |   1
                    //      |

                // Make each cell between 0.0 - 1.0
                _st = 1 - frac(_st);

                // Rotate each cell according to the index
                if(index == 1.0)
                {
                    //  Rotate cell 1 by 90 degrees
                    _st = rotate2D(_st,PI * -0.5);
                } 
                else if(index == 2.0)
                {
                    //  Rotate cell 2 by -90 degrees
                    _st = rotate2D(_st,PI * 0.5);
                } 
                else if(index == 3.0)
                {
                    //  Rotate cell 3 by 180 degrees
                    _st = rotate2D(_st,PI);
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


                float2 st = Tile(uv, _Tile);
                
                #if _DIR_ROTATE
                    st = RotateTilePattern(st);
                #elif _DIR_TILE 
                     st = Tile(st,2.0);
                #elif _DIR_TIME
                     st = rotate2D(st,-PI * _Time.y * 0.25);
                #elif _DIR_UV2
                    st = RotateTilePattern(st * 2.);
                #elif _DIR_PITIME
                    st = rotate2D(st,PI * _Time.y * 0.25);
                #endif

                col.rgb = step(st.x,st.y);

                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}