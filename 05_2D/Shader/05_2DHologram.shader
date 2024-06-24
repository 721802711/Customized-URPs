Shader "B/05_2DHologram"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _HologramStripesAmount ("Stripes Amount", Range(0, 1)) = 0.1 //条纹数量
        _HologramStripesSpeed ("Stripes Speed", Range(-20, 20)) = 4.5 //条纹移动速度
        _HologramMinAlpha ("Min Alpha", Range(0, 1)) = 0.1 //最小的alpha值
        _HologramMaxAlpha ("Max Alpha", Range(0, 1)) = 0.75 //最大的alpha值
        _HologramStripeColor ("Stripes Color", Color) = (0, 1, 1, 1) //条纹颜色
        _HologramBlend ("Hologram Blend", Range(0, 1)) = 1 //颜色混合程度
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
            half _HologramStripesAmount, _HologramMinAlpha, _HologramStripesSpeed, _HologramMaxAlpha, _HologramBlend;
            half4 _HologramStripeColor;
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
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //用于将一个范围内的值映射到另一个范围内
            half RemapFloat(half inValue, half inMin, half inMax, half outMin, half outMax) {
                return outMin + (inValue - inMin) * (outMax - outMin) / (inMax - inMin);
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

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                
                half totalHologram = _HologramStripesAmount;
                half hologramYCoord = ((i.uv.y + (((_Time.x) % 1) * _HologramStripesSpeed)) % totalHologram) / totalHologram;//计算全息条纹的Y坐标位置
                hologramYCoord = abs(hologramYCoord);//取全息条纹的绝对值，确保Y坐标在正数范围内
                half alpha = RemapFloat(saturate(hologramYCoord), 0.0, 1.0, _HologramMinAlpha, saturate(_HologramMaxAlpha));//根据条纹的Y坐标计算alpha值
                half hologramMask = max(sign(-hologramYCoord), 0.0);//计算一个用于控制全息效果的显示范围的值
                half4 hologramResult = col;
                hologramResult.a *= lerp(alpha, 1, hologramMask);//根据计算的alpha值和掩码值，调整hologramResult的alpha通道值
                hologramResult.rgb *= max(1, _HologramMaxAlpha * max(sign(hologramYCoord), 0.0));//根据条纹的Y坐标位置，调整hologramResult的RGB颜色值
                hologramMask = 1 - step(0.01, hologramMask);//根据掩码值，计算一个反向掩码。如果掩码值小于0.01，则将其设置为1，否则设置为0
                hologramResult.rgb += hologramMask * _HologramStripeColor * col.a;//根据反向掩码，添加全息条纹的颜色
                col = lerp(col, hologramResult, _HologramBlend);//将原始颜色col和经过全息效果处理后的颜色hologramResult进行混合


                return col;
            }
            ENDHLSL
        }
    }
}