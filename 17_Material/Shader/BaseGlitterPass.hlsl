#ifndef MLIBRARY_LIT_INCLUDED
#define MLIBRARY_LIT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
TEXTURE2D(_SnowNoise);    SAMPLER(sampler_SnowNoise);
TEXTURE2D(_SnowNormal);   SAMPLER(sampler_SnowNormal);
TEXTURE2D(_SparkleNoise); SAMPLER(sampler_SparkleNoise);

CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST; float4 _SnowNoise_ST; float4 _SnowNormal_ST; float4 _SparkleNoise_ST;
    half4  _MainColor;  half4 _SnowColor;
    half   _SnowNormalScale;
    // 新增：双层法线混合参数
    half   _NormalDetailTiling;
    half   _NormalDetailStrength;

    half   _SnowLevel;  half _SnowBlur;
    float4 _SnowDirection; half _SnowOffset;
    half4  _SparkleColor; float _SparklePower; float _ShiningSpeed; float _HeightFactor;
    half   _SnowSmoothness; half4 _SnowSpecColor;
CBUFFER_END

struct appdata {
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
};

struct v2f {
    float4 posCS : SV_POSITION;
    float2 uv : TEXCOORD0;         
    float2 snowUV : TEXCOORD1;     
    float2 sparkleUV : TEXCOORD3;  
    float2 normalUV : TEXCOORD4;   
    float3 normalWS : TEXCOORD5;
    float3 viewDirWS : TEXCOORD6;
    float3 tangentWS : TEXCOORD7;  
    float3 bitangentWS : TEXCOORD8;
};

// 辅助函数：法线混合 (RNM 简化版，确保法线方向正确重定向)
float3 BlendNormals(float3 n1, float3 n2)
{
    return normalize(float3(n1.xy + n2.xy, n1.z * n2.z));
}

v2f vert (appdata v) {
    v2f o;
    VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
    float3 posWS = posInputs.positionWS;
    float3 normWS = TransformObjectToWorldNormal(v.normalOS);
    float3 snowDir = normalize(_SnowDirection.xyz);

    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.snowUV = TRANSFORM_TEX(v.uv, _SnowNoise);
    o.sparkleUV = TRANSFORM_TEX(v.uv, _SparkleNoise);
    o.normalUV = TRANSFORM_TEX(v.uv, _SnowNormal);

    half vNoise = SAMPLE_TEXTURE2D_LOD(_SnowNoise, sampler_SnowNoise, o.snowUV, 0).r;
    half mask = smoothstep(_SnowLevel, _SnowLevel + _SnowBlur, dot(normWS, snowDir) * vNoise);
    posWS += snowDir * (mask * _SnowOffset);

    o.posCS = TransformWorldToHClip(posWS);
    o.normalWS = normWS;
    o.viewDirWS = GetWorldSpaceViewDir(posWS);

    float3 up = abs(normWS.y) < 0.999 ? float3(0,1,0) : float3(1,0,0);
    o.tangentWS = normalize(cross(up, normWS));
    o.bitangentWS = cross(normWS, o.tangentWS);

    return o;
}

half4 frag (v2f i) : SV_Target {
    float3 normWS = normalize(i.normalWS);
    float3 viewWS = normalize(i.viewDirWS);
    float3 snowDir = normalize(_SnowDirection.xyz);
    Light mainLight = GetMainLight();
    float3 lightDir = normalize(mainLight.direction);
    
    // 1. 采样积雪掩码
    half maskNoise = SAMPLE_TEXTURE2D(_SnowNoise, sampler_SnowNoise, i.snowUV).r;
    half pMask = smoothstep(_SnowLevel, _SnowLevel + _SnowBlur, dot(normWS, snowDir) * maskNoise);

    // 2. 双层随机法线混合
    // 第一层：基础法线
    float3 n1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_SnowNormal, sampler_SnowNormal, i.normalUV), _SnowNormalScale);
    
    // 第二层：细节法线 (随机偏移 + 不同缩放)
    float2 detailUV = i.normalUV * _NormalDetailTiling + float2(0.41, 0.73); 
    float3 n2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_SnowNormal, sampler_SnowNormal, detailUV), _NormalDetailStrength);
    
    // 混合两层法线
    float3 snowNormalTS = BlendNormals(n1, n2);
    
    float3x3 TBN = float3x3(i.tangentWS, i.bitangentWS, normWS);
    float3 mixedNormalWS = normalize(mul(snowNormalTS, TBN));

    // 3. 高光逻辑 (与混合法线耦合)
    half3 specColor = half3(0,0,0);
    if(pMask > 0.01)
    {
        float3 halfVec = normalize(lightDir + viewWS);
        float specExp = exp2(8.0 * _SnowSmoothness + 1.0); 
        float NdotH = saturate(dot(mixedNormalWS, halfVec));
        specColor = pow(NdotH, specExp) * _SnowSpecColor.rgb * mainLight.color;
    }

    // 4. 视差闪烁
    float3 viewTS = mul(TBN, viewWS);
    float time = _Time.y * _ShiningSpeed;
    float2 uvOff = viewTS.xy * maskNoise * _HeightFactor;
    float nS1 = SAMPLE_TEXTURE2D(_SparkleNoise, sampler_SparkleNoise, i.sparkleUV + float2(time, time) + uvOff).r;
    float nS2 = SAMPLE_TEXTURE2D(_SparkleNoise, sampler_SparkleNoise, i.sparkleUV * 0.8 - float2(time, -time) + uvOff).r;
    half sparkle = pow(nS1 * nS2 * 2.5, _SparklePower);

    // 5. 最终混合
    half NdotL = saturate(dot(mixedNormalWS, lightDir));
    half4 base = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _MainColor;
    
    half3 finalSnow = _SnowColor.rgb * (NdotL + 0.15) + specColor + (sparkle * _SparkleColor.rgb * _SparkleColor.a);
    half baseNdotL = saturate(dot(normWS, lightDir));
    
    half3 res = lerp(base.rgb * baseNdotL, finalSnow, pMask);

    return half4(res, base.a);
}
#endif