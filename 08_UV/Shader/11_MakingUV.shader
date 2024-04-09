Shader "B/11_MakingUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} 
        [Space(20)]     
        _Size ("Size" ,Float) = 1
        _T ("Time", Float) = 1
        _Distortion ("Distortion", Range(-5,5)) = 0.1
        
        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5   // 源混合模式
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10  // 目标混合模式
    } 
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline"="UniversalPipeline"}
        Blend[_SrcBlend][_DstBlend]

        Cull Off 

        LOD 100 

        HLSLINCLUDE 

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

        CBUFFER_START(UnityPerMaterial) 
            float4 _MainTex_ST;
            float _Size, _T, _Distortion;
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

        TEXTURE2D(_MainTex);                   SAMPLER(sampler_MainTex);
        ENDHLSL 

        Pass 
        {
            HLSLPROGRAM 
            
            #pragma vertex vert 
            #pragma fragment frag 

            // 定义函数快捷方式
            #define S(a, b, t) smoothstep(a,b,t)   

            float N21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 23.33);
                return frac(p.x * p.y);
            }



            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz); // 获取顶点位置输入
                o.positionCS = PositionInputs.positionCS; // 获取齐次空间位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // 纹理坐标变换

                return o;
            }

            half4 frag (v2f i, bool face : SV_isFrontFace) : SV_Target 
            {


                // half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv); 
                float t = fmod(_Time.y + _T , 7200);
                half4 col = half4(0, 0, 0, 1);

                // GL uv
                float2 u_GL = float2(0,0);
                u_GL.x = i.uv.x;
                u_GL.y = 1 - i.uv.y;


                float2 aspect = float2(2,1);
                float2 uv = u_GL * _Size * aspect;
                uv.y += t * 0.25;
                float2 gv = frac(uv) - 0.5;
                float2 id = floor(uv);

                float n = N21(id); // 0 1
                t += n * 6.2831;


                float w = u_GL.y * 10;
                float x = (n - 0.5) * 0.8;  // [-0.4, 0.4]
                x += (0.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * 0.45;
                float y = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
                y -= (gv.x - x) * (gv.x -x);

                float2 dropPos = (gv - float2(x, y)) / aspect;
                float drop = S(0.05, 0.03, length(dropPos));


                float2 trailPos = (gv - float2(x, y)) / aspect;
                trailPos.y = (frac(trailPos.y * 10)- 0.5) / 20;
                float trail = S(0.03, 0.01, length(trailPos));
                float fogTrail = S(-0.05, 0.05, dropPos.y);
                fogTrail *= S(0.5, y, gv.y);
                trail *= fogTrail;
                fogTrail *= S(0.05, 0.04, abs(dropPos.x));

                col += fogTrail * 0.5;
                col += trail;
                col += drop;


                float2 offs = (drop * dropPos + trail * trailPos);

                col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv + offs * _Distortion);
                // 绘制网格
                if (gv.x > 0.48 || gv.y > 0.49) col = half4(1, 0, 0, 1);      
                // 为什么设 0.48 - 0.49 会有一条线， 是因为我们的UV是 - 0.5 - 0.5 

                return col;
            }
            ENDHLSL 
        }
    }
} 