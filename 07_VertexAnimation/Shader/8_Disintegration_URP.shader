Shader "LSQ/URP/HLSL_Disintegration_GS"
{
    Properties
    {
        [Header(Base)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20

        [Header(Dissolve)]
        _DissolveTexture("Dissolve Texutre", 2D) = "white" {}
        _DissolveBorderColor("Dissolve Border Color", Color) = (1, 1, 1, 1)
        _DissolveBorderWidth("Dissolve Border", float) = 0.05
        _Weight("Weight", Range(0, 1)) = 0

        [Header(Particle)]
        _Direction("Direction", Vector) = (0, 0, 0, 0)
        _FlowMap("Flow (RG)", 2D) = "black" {}
        _Exapnd("Expand", float) = 1
        _ParticleShape("Shape", 2D) = "white" {}
        _ParticleRadius("Radius", float) = 0.1
        [Toggle]_ParticleLit("Use Lit", int) = 1
        [HDR]_ParticleColor("Particle Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" } // 等价于 ForwardBase，用 URP 名称
            Cull Off

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex   vert
            #pragma geometry geom
            #pragma fragment frag

            // URP 核心+光照
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ====== 常量与采样器 ======
            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_DissolveTexture);    SAMPLER(sampler_DissolveTexture);
            TEXTURE2D(_FlowMap);            SAMPLER(sampler_FlowMap);
            TEXTURE2D(_ParticleShape);      SAMPLER(sampler_ParticleShape);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float4 _Specular;
                float  _Gloss;

                float4 _DissolveBorderColor;
                float  _DissolveBorderWidth;
                float  _Weight;

                float4 _FlowMap_ST;
                float  _Exapnd;
                float4 _Direction;

                float  _ParticleRadius;
                float4 _ParticleColor;
                int    _ParticleLit;
            CBUFFER_END

            // ====== 结构体 ======
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2g
            {
                float4 objPos : POSITION; // object space pos
                float2 uv     : TEXCOORD0;
                float3 normal : NORMAL;    // object space normal
            };

            struct g2f
            {
                float4 pos      : SV_POSITION; // clip space
                float2 uv       : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 worldPos : TEXCOORD2;   // w<0 => 原模型; w>0 => 粒子
            };

            // ====== 工具函数 ======
            float2 TransformUV(float2 uv, float4 st) { return uv * st.xy + st.zw; }

            float remap(float v, float a, float b, float c, float d)
            { return (v - a) / (b - a) * (d - c) + c; }

            float4 RemapFlow(float4 t)
            {
                return float4(
                    remap(t.x, 0, 1, -1, 1),
                    remap(t.y, 0, 1, -1, 1),
                    0,
                    remap(t.w, 0, 1, -1, 1)
                );
            }

            // ====== VS ======
            v2g vert(appdata v)
            {
                v2g o;
                o.objPos = v.vertex;
                o.uv     = v.uv;
                o.normal = v.normal;
                return o;
            }

            // ====== GS ======
            [maxvertexcount(7)] // 粒子Quad(4) + 原三角(3)
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                // 三角形平均信息（object space）
                float2 uvAvg      = (IN[0].uv + IN[1].uv + IN[2].uv) / 3.0;
                float3 posO_Avg   = (IN[0].objPos.xyz + IN[1].objPos.xyz + IN[2].objPos.xyz) / 3.0;
                float3 nO_Avg     = normalize((IN[0].normal + IN[1].normal + IN[2].normal) / 3.0);

                // 转世界
                float3 posW_Avg   = TransformObjectToWorld(float4(posO_Avg, 1)).xyz;
                float3 nW_Avg     = TransformObjectToWorldNormal(nO_Avg);

                // 溶解强度（按平均uv）
                float dissolveVal = SAMPLE_TEXTURE2D_LOD(_DissolveTexture, sampler_DissolveTexture, uvAvg, 0).r;
                float t           = saturate(_Weight * 2.0 - dissolveVal);

                // Flow UV：用世界XZ并做ST
                float2 flowUV     = TransformUV(posW_Avg.xz, _FlowMap_ST);
                float4 flowVec    = RemapFlow(SAMPLE_TEXTURE2D_LOD(_FlowMap, sampler_FlowMap, flowUV, 0));

                // 伪随机位移（世界空间处理更稳）
                float3 dstW       = posW_Avg + _Direction.xyz + flowVec.xyz * _Exapnd;

                // 根据t在原位与偏移位之间插值
                float3 pW         = lerp(posW_Avg, dstW, t);
                float  radiusW    = lerp(_ParticleRadius, 0.0, t);

                if (t > 0.0) // 生成面向相机的粒子四边形（世界空间）
                {
                    // 相机在世界空间的右/上（使用视图矩阵的逆）
                    float3 camRightW = UNITY_MATRIX_I_V[0].xyz;
                    float3 camUpW    = UNITY_MATRIX_I_V[1].xyz;

                    float3 p0 = pW + radiusW * camRightW - radiusW * camUpW;
                    float3 p1 = pW + radiusW * camRightW + radiusW * camUpW;
                    float3 p2 = pW - radiusW * camRightW - radiusW * camUpW;
                    float3 p3 = pW - radiusW * camRightW + radiusW * camUpW;

                    g2f o;
                    o.normalWS = normalize(nW_Avg);

                    o.pos      = TransformWorldToHClip(float4(p0, 1));
                    o.uv       = float2(1, 0);
                    o.worldPos = float4(p0, 1); // w>0 表示粒子
                    triStream.Append(o);

                    o.pos      = TransformWorldToHClip(float4(p1, 1));
                    o.uv       = float2(1, 1);
                    o.worldPos = float4(p1, 1);
                    triStream.Append(o);

                    o.pos      = TransformWorldToHClip(float4(p2, 1));
                    o.uv       = float2(0, 0);
                    o.worldPos = float4(p2, 1);
                    triStream.Append(o);

                    o.pos      = TransformWorldToHClip(float4(p3, 1));
                    o.uv       = float2(0, 1);
                    o.worldPos = float4(p3, 1);
                    triStream.Append(o);
                }
                else // 保留原三角（object space 直接转裁剪空间）
                {
                    [unroll]
                    for (int j = 0; j < 3; j++)
                    {
                        g2f o;
                        o.pos      = TransformObjectToHClip(IN[j].objPos);
                        o.uv       = TransformUV(IN[j].uv, _MainTex_ST);
                        o.normalWS = normalize(TransformObjectToWorldNormal(IN[j].normal));
                        float3 wp  = TransformObjectToWorld(IN[j].objPos).xyz;
                        o.worldPos = float4(wp, -1); // w<0 表示原模型
                        triStream.Append(o);
                    }
                }
            }

            // ====== PS ======
            half4 frag(g2f i) : SV_Target
            {
                // 主光 + 环境（URP）
                Light mainLight = GetMainLight();
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 L = normalize(mainLight.direction);   // 来自 URP Lighting.hlsl
                float  NdotL = saturate(dot(N, L));
                float3 diffuse = mainLight.color * NdotL;
                float3 H = normalize(L + V);
                float3 specular = mainLight.color * _Specular.rgb * pow(saturate(dot(N, H)), _Gloss);

                float3 ambient = SampleSH(N); // 环境球谐

                float4 col = 1;

                if (i.worldPos.w < 0) // 原模型片元
                {
                    float  dissolve = SAMPLE_TEXTURE2D(_DissolveTexture, sampler_DissolveTexture, i.uv).r;
                    float4 baseCol  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                    col.rgb = ambient * baseCol.rgb + diffuse * baseCol.rgb + specular;

                    if (_Weight > 0.0)
                    {
                        // 边缘发光
                        col += _DissolveBorderColor * step(dissolve - 2.0 * _Weight, _DissolveBorderWidth);
                    }
                }
                else // 粒子片元
                {
                    float s = SAMPLE_TEXTURE2D(_ParticleShape, sampler_ParticleShape, i.uv).r;
                    clip(s - 0.5); // 形状裁剪

                    float3 lit = ambient * _ParticleColor.rgb + diffuse * _ParticleColor.rgb + specular;
                    col.rgb = lerp(_ParticleColor.rgb, lit, (_ParticleLit != 0));
                    col.a   = 1;
                }

                return col;
            }

            ENDHLSL
        }
    }
}
