// URP-compatible version of PPX_Stand_shader
Shader "B/11_18_EffectCharacter"
{
    Properties
    {
        _Alpha("Alpha", Float) = 1
        _Base_Tex("Base_Tex", 2D) = "white" {}
        [HDR]_Base_color("Base_color", Color) = (1,1,1,0)
        _Side_Tex("Side_Tex", 2D) = "white" {}
        [HDR]_side_color("side_color", Color) = (1,1,1,0)
        _side_power("side_power", Range(0,3)) = 1
        [HDR]_frensel_outside("frensel_outside", Color) = (1,0.92775,0.6462264,0)
        [HDR]_frensel_inside("frensel_inside", Color) = (0,0,0,0)
        _min("min", Range(0,1)) = 0.1554975
        _edge("edge", Range(0,1)) = 0.6705883
        [NoScaleOffset]_star_Tex("star_Tex", 2D) = "white" {}
        _Point_uv("Point_uv", Vector) = (1,1,0,0)
        _Point_speed("Point_speed", Vector) = (1,0,0,0)
        [HDR]_star_color("star_color", Color) = (1,1,1,0)
        _star_color_power("star_color_power", Range(0,3)) = 1
        [NoScaleOffset]_Disslove_Tex("Disslove_Tex", 2D) = "white" {}
        _Disslove_uv("Disslove_uv", Vector) = (1,1,0,0)
        _Disslove_speed("Disslove_speed", Vector) = (1,0,0,0)
        _Dissolve("Dissolve", Range(0,1)) = 0.991495
        _Hardness("Hardness", Range(0,22)) = 11
        _Mask("Mask", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 0
        [Enum(off,0,on,1)]_ZWrite("ZWrite", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Float) = 4
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite[_ZWrite]
            Cull[_Cull]
            ZTest[_ZTest]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
            };

            TEXTURE2D(_Base_Tex); SAMPLER(sampler_Base_Tex);
            TEXTURE2D(_Side_Tex); SAMPLER(sampler_Side_Tex);
            TEXTURE2D(_star_Tex); SAMPLER(sampler_star_Tex);
            TEXTURE2D(_Disslove_Tex); SAMPLER(sampler_Disslove_Tex);
            TEXTURE2D(_Mask); SAMPLER(sampler_Mask);



        CBUFFER_START(UnityPerMaterial)
            float4 _Base_Tex_ST;
            float4 _Side_Tex_ST;
            float4 _Mask_ST;
            float4 _star_Tex_ST;
            float4 _Disslove_Tex_ST;
            float4 _Base_color;
            float4 _side_color;
            float4 _Point_uv;
            float4 _Point_speed;
            float4 _Disslove_uv;
            float4 _Disslove_speed;
            float4 _star_color;
            float4 _frensel_outside;
            float4 _frensel_inside;
            float _Alpha, _side_power, _star_color_power, _Dissolve, _Hardness, _min, _edge;
        CBUFFER_END



            Varyings vert(Attributes v)
            {
                Varyings o;

                
                float3 worldPos = TransformObjectToWorld(v.positionOS.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                float4 clipPos = TransformObjectToHClip(v.positionOS);

                
                o.vertex = clipPos;
                o.worldPos = worldPos;
                o.uv = v.uv;

    
                o.worldNormal = worldNormal;


                o.screenPos = ComputeScreenPos(clipPos);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 worldPos = i.worldPos;
                float3 worldNormal = normalize(i.worldNormal);
                float2 uv = i.uv;

                // 计算视角方向
                float3 viewDir = normalize(GetWorldSpaceViewDir(worldPos));

                // Fresnel 混合
                float ndotv = dot(viewDir, worldNormal);
                float fresnel = smoothstep(_min, _min + _edge, abs(ndotv));
                float4 fresnelColor = lerp(_frensel_outside, _frensel_inside, fresnel);

                // Base 和 Side UV
                float2 uv_Base = uv * _Base_Tex_ST.xy + _Base_Tex_ST.zw;
                float2 uv_Side = uv * _Side_Tex_ST.xy + _Side_Tex_ST.zw;

                // 获取屏幕 UV（用于 Dissolve、Star 动效）
                float4 screenPos = i.screenPos;
                float2 screenUV = (screenPos.xy / screenPos.w);

            #if UNITY_UV_STARTS_AT_TOP
                screenUV.y = 1.0 - screenUV.y;
            #endif

                // Dissolve 与 Star UV 动画
                float2 point_uv_scale = _Point_uv.xy;
                float2 point_uv_offset = _Point_uv.zw;
                float2 point_speed = _Point_speed.xy;
                float point_time = _Time.y * _Point_speed.z;

                float2 dissolve_uv_scale = _Disslove_uv.xy;
                float2 dissolve_uv_offset = _Disslove_uv.zw;
                float2 dissolve_speed = _Disslove_speed.xy;
                float dissolve_time = _Time.y * _Disslove_speed.z;

                float2 starUV = screenUV * point_uv_scale + point_uv_offset + (-point_speed * point_time);
                float2 dissolveUV = screenUV * dissolve_uv_scale + dissolve_uv_offset + (-dissolve_speed * dissolve_time);

                // Dissolve 强度
                float hardness = _Hardness;
                float dissolveThreshold = lerp(hardness, -1.0, _Dissolve);
                float dissolveMask = SAMPLE_TEXTURE2D(_Disslove_Tex, sampler_Disslove_Tex ,dissolveUV).r;
                float dissolveFactor = saturate(dissolveMask * hardness - dissolveThreshold);

                // Star 发光计算
                float4 starCol = SAMPLE_TEXTURE2D(_star_Tex, sampler_star_Tex, starUV) * dissolveFactor * _star_color * _star_color_power;

                // 主纹理
                float4 baseCol = SAMPLE_TEXTURE2D(_Base_Tex, sampler_Base_Tex, uv_Base) * _Base_color;

                // 边缘纹理
                float4 sideCol = SAMPLE_TEXTURE2D(_Side_Tex, sampler_Side_Tex, uv_Side) * _side_color * _side_power;

                // 遮罩控制透明度
                float2 uv_Mask = uv * _Mask_ST.xy + _Mask_ST.zw;
                float alphaMask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, uv_Mask).r;

                // 合成颜色
                float3 finalRGB = baseCol.rgb + fresnelColor.rgb + sideCol.rgb + starCol.rgb;
                float finalAlpha = _Alpha * alphaMask;

                return float4(finalRGB, finalAlpha);
            }

            ENDHLSL
        }
    }
}
