Shader "B/11_14_UVAnimation"
{
    Properties
    {
        [HDR]_BaseColor("BaseColor",Color)=(1,1,1,1)
        _MainTex("MainTex",2D)="White"{}

        _x_Sum("x", Float) = 3
        _y_Sum("y", Float) = 3 
        _ShowID("_ShowID", Float) = 0
        [Toggle(_AutoPlay)] _AutoPlay("Play",Float) = 0
        _Speed("_Speed",Float) = 1

        [KeywordEnum(LOCK_Y,FREE_Y)] _Y_STAGE("_Y_STAGE",Float) = 0      


		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
    }
    SubShader
    {
        Tags{  "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend[_SrcBlend][_DstBlend]

        Cull Off
        ZWrite Off

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Speed;
        float _ShowID;
        float _x_Sum, _y_Sum;
        CBUFFER_END

            struct appdata
            {
                float4 positionOS:POSITION;
                float2 texcoord:TEXCOORD;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float2 uv:TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);
        ENDHLSL


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            #pragma shader_feature  _AutoPlay

            #pragma shader_feature_local _Y_STAGE_LOCK_Y      

            v2f vert (appdata v)
            {
                v2f o;

                //先计算基于视角坐标系的Z轴 
                //获得模型空间的相机坐标作为新坐标的z轴 
                float3 newZ = normalize(TransformWorldToObject(_WorldSpaceCameraPos));  

                //判断是否开启了锁定Y轴
                #ifdef _Y_STAGE_LOCK_Y
                    newZ.y = 0;
                #endif

                //根据Z轴去判断X的方向
                float3 newX = normalize(abs(newZ.y) < 0.99 ? cross(float3(0,1,0),newZ):cross(newZ,float3(0,0,1)));
                float3 newY = normalize(cross(newZ,newX));

                //计算出旋转矩阵M
                float3x3 Matrix = {newX,newY,newZ};  
                float3 newpos = mul(v.positionOS.xyz,Matrix);

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(newpos);
                o.positionCS = PositionInputs.positionCS;   

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                #ifdef _AutoPlay
                    _ShowID += _Time.y * _Speed;
                #endif
                
                _ShowID = floor(_ShowID % (_x_Sum * _y_Sum));        // 取整数


                float indexY = floor(_ShowID / _x_Sum);
                float indexX = _ShowID - _x_Sum * indexY;

                float2 AnimUV = float2(i.uv.x / _x_Sum, i.uv.y / _y_Sum);
                AnimUV.x += indexX / _x_Sum;
                AnimUV.y +=(_y_Sum-1 - indexY )/ _y_Sum;

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,AnimUV) * _BaseColor;     
                col.a = _BaseColor.a;
                return col;
            }
            ENDHLSL
        }
    }
}