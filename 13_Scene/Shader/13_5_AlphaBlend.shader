Shader "DFW/Scenes/AlphaBlend"
{
    Properties
    {
        _TintColor("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex("Particle Texture", 2D) = "white" {}
        _InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
    }

    SubShader
    {
        Tags { "Queue"="Transparent-30" "RenderType"="Transparent" "IgnoreProjector"="True" }
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back
        ColorMask RGB
        Lighting Off

        Pass
        {
            Name "ForwardAlphaParticle"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_particles
            #pragma multi_compile_fog

            #pragma multi_compile _ SOFTPARTICLES_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _TintColor;
                float _InvFade;
            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 projPos : TEXCOORD1;
                half fogCoord: TEXCOORD2;          // ‰≥ˆŒÌ–ß
            };

            Varyings vert(Attributes input)
            {
                Varyings o;
                float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);
                o.positionCS = positionCS;
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.color = input.color;

                #ifdef SOFTPARTICLES_ON
                o.projPos = ComputeScreenPos(positionCS);
                COMPUTE_EYEDEPTH(o.projPos.z);
                #else
                o.projPos = float4(0, 0, 0, 1);
                #endif

                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 col = i.color * _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                #ifdef SOFTPARTICLES_ON
                float sceneZ = LinearEyeDepth(SAMPLE_TEXTURE2D_PROJ(_CameraDepthTexture, sampler_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r);
                float partZ = i.projPos.z;
                float fade = saturate(_InvFade * (sceneZ - partZ));
                col.a *= fade;
                #endif

                col.rgb = MixFog(col.rgb,i.fogCoord);

                return col;
            }

            ENDHLSL
        }
    }

}
