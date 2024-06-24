#ifndef LIGHTING_FUN_INCLUDED
#define LIGHTING_FUN_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"


CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST;
    float4 _DiffuseColor;
    float4 _SpecularColor, _AmbientColor;
    float _smoothness, _CutOff;
CBUFFER_END


TEXTURE2D(_MainTex);                          SAMPLER(sampler_MainTex);

// ==========================================================================================================


half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}
half3 Specular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(max(0,NdotH), smoothness);
    half3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}



half3 SimpleLightingDSA(half3 lightColor, half3 lightDir, half lightAttenuation, half3 normalWS, half3 viewDirectionWS,half3 albedo)
{
    // 漫反射                   
    half3 diffuse = Lambert(lightColor, lightDir, normalWS) * lightAttenuation * _DiffuseColor.rgb;
    // 高光计算
    half smoothness = exp2(10 * _smoothness + 1);
    half3 specular = Specular(lightColor, lightDir, normalWS, viewDirectionWS, _SpecularColor, smoothness);
    // 环境光
    half3 ambient = SampleSH(normalWS).rgb * _AmbientColor.rgb * _AmbientColor.a;
    // 合并
    half3 color = (ambient + diffuse) * albedo.rgb;
    color += specular;
    return color;     
}


//第一个函数读取等光信息，世界空间下法线位置，世界空间视角位置
half3 B_LightingData(Light light, half3 normalWS, half3 viewDirectionWS, half3 albedo)
{
    half3 LightColor = light.color;    
    half3 LightDir = normalize(light.direction);                //获取光照方向
    half LightAttenuation = light.distanceAttenuation * light.shadowAttenuation;                            // 计算光源衰减
    half3 attenuatedLightColor = LightColor.rgb * LightAttenuation;                                             // 计算衰减后的光照颜色
    return SimpleLightingDSA(attenuatedLightColor, LightDir, LightAttenuation, normalWS, viewDirectionWS,albedo);
}

// ==========================================================================================================




#endif
