﻿#ifndef PBR_FUNCTIONS_INCLUDED
#define PBR_FUNCTIONS_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"           
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// =========================================================================================================

// D

float Distribution(float roughness, float nh)
{
	float lerpSquareRoughness = pow(lerp(0.01,1, roughness),2);                  // 这里限制最小高光点
	float D = lerpSquareRoughness / (pow((pow(nh,2) * (lerpSquareRoughness - 1) + 1), 2) * PI);
	return D;
}
// 直接光照 G项子项
inline real G_subSection(half dot, half k)
{
    return dot / lerp(dot, 1, k);
}

// 这里计算G的方法
float Geometry(float roughness, float nl, float nv)
{
    //half k = pow(roughness + 1,2)/8.0;          // 直接光的K值  

    //half k = pow(roughness,2)/2;                // 间接光的K值

    half k = pow(1 + roughness, 2) * 0.5;             

    float GLeft = G_subSection(nl,k);           // 第一部分的 G 
    float GRight = G_subSection(nv,k);          // 第二部分的 G
    float G = GLeft * GRight;
    return G;
}
// F
float3 FresnelEquation(float3 F0,float lh)
{
		float3 F = F0 + (1 - F0) * exp2((-5.55473 * lh - 6.98316) * lh);
		return F;
}

// 反射探针漫反射
float3 SH_IndirectionDiff(float3 normalWS)
{
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    float3 Color = SampleSH9(SHCoefficients,normalWS);
    return max(0,Color);
}
// 间接光 F
float3 IndirF_Function(float NdotV, float3 F0, float roughness)
{
    float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
    return F0 + Fre * saturate(1 - roughness - F0);
}

//间接光高光 反射探针
real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
{
    float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // 计算出反射向量 
    roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity内部不是线性 调整下拟合曲线求近似
    float MidLevel = roughness * 6;                                                                    // 把粗糙度remap到0-6 7个阶级 然后进行lod采样
    float4 speColor = saturate(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel));//根据不同的等级进行采样
#if !defined(UNITY_USE_NATIVE_HDR)
    return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
#else
    return speColor.xyz*AO;
#endif
}

// 间接光高光影响因子
half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
{
    #ifdef UNITY_COLORSPACE_GAMMA
    half SurReduction = 1 - 0.28 * roughness * roughness;
    #else
    half SurReduction = 1 / (roughness * roughness + 1);
    #endif
    #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
    half Reflectivity = BRDFspe.x;
    #else
    half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
    #endif
    half GrazingTSection = saturate(Reflectivity + smoothness);
    half fre = Pow4(1 - NdotV);  
    // Lighting.hlsl 第 501 行
    // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
    return lerp(F0, GrazingTSection, fre) * SurReduction;
}
// PBR 全函数
half3 PBR(float3 view,float3 normal,float3 position, float3 albedo, float rough, float metal, float ao, float smoothness, float3 emissive)
{

    // 函数内
    half4 shadowCoord = TransformWorldToShadowCoord(position);                  // 计算阴影
    Light mainLight = GetMainLight(shadowCoord);                                             // 获取光照 
    half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;        // 计算距离衰减和阴影衰减
    half4 lightColor = float4(mainLight.color,1);                                 // 获取光照颜色


    float3 viewDir   = normalize(view);
    float3 normalDir = normalize(normal);
    float3 lightDir  = normalize(mainLight.direction);                            // 获取光照颜色
    float3 halfDir   = normalize(viewDir + lightDir);

    float nh = max(saturate(dot(normalDir, halfDir)), 0.001);
    float nl = max(saturate(dot(normalDir, lightDir)),0.001);
    float nv = max(saturate(dot(normalDir, viewDir)),0.01);
    float vh = max(saturate(dot(viewDir, halfDir)),0.0001);
    float hl = max(saturate(dot(halfDir, lightDir)), 0.0001);

    half3 F0 = lerp(0.04,albedo.rgb,metal);

    half D = Distribution(rough, nh);
    half G = Geometry(rough,nl,nv);
    half3 F = FresnelEquation(F0,hl); 

    half3 ks = F;
    half3 kd = (1- ks) * (1 - metal);                   // 计算kd

    // 直接光部分
    half3 SpecularResult = (D * G * F) / (nv * nl * 4);
    lightColor.rgb *= atten;                         // 增加阴影 衰减
    half3 DirectSpeColor = saturate(SpecularResult * lightColor.rgb * (nl * PI * ao));
    half3 DirectDiffColor = kd * albedo.rgb * lightColor.rgb * nl * atten;                   // 增加阴影 衰减
    DirectDiffColor += emissive;
    half3 directLightResult = DirectDiffColor + DirectSpeColor;

    //间接光部分
    half3 shcolor = SH_IndirectionDiff(normalDir) * ao;                                       // 这里可以AO
    half3 indirect_ks = IndirF_Function(nv,F0,rough);                                         // 计算 ks
    half3 indirect_kd = (1 - indirect_ks) * (1 - metal);
    half3 indirectDiffColor = shcolor * indirect_kd * albedo;

    half3 IndirectSpeCubeColor = IndirectSpeCube(normalDir, viewDir, rough, ao);
    half3 IndirectSpeCubeFactor = IndirectSpeFactor(rough, smoothness, SpecularResult, F0, nv);

    half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;
    half3 IndirectColor = IndirectSpeColor + indirectDiffColor;

    return directLightResult + IndirectColor; 

} 

half3 PBRDirectLightResult(Light light, float3 view,float3 normal, float3 albedo, float rough, float metal)
{
    half4 lightColor = float4(light.color,1);                                 // 获取光照颜色
    float3 viewDir   = normalize(view);
    float3 normalDir = normalize(normal);
    float3 lightDir  = normalize(light.direction);                            // 获取光照颜色
    float3 halfDir   = normalize(viewDir + lightDir);

    float nh = max(saturate(dot(normalDir, halfDir)), 0.001);
    float nl = max(saturate(dot(normalDir, lightDir)),0.001);
    float nv = max(saturate(dot(normalDir, viewDir)),0.01);
    float vh = max(saturate(dot(viewDir, halfDir)),0.0001);
    float hl = max(saturate(dot(halfDir, lightDir)), 0.0001);

    half3 F0 = lerp(0.04,albedo.rgb,metal);

    half D = Distribution(rough, nh);
    half G = Geometry(rough,nl,nv);
    half3 F = FresnelEquation(F0,hl); 

    half3 ks = F;
    half3 kd = (1- ks) * (1 - metal);                   // 计算kd


    half3 SpecularResult = (D * G * F) / (nv * nl * 4);

    half3 DirectSpeColor = saturate(SpecularResult * lightColor.rgb * nl * PI );
    half3 DirectDiffColor = kd * albedo.rgb * lightColor.rgb * nl;    

    half3 directLightResult = DirectDiffColor + DirectSpeColor;
    return directLightResult;
}


#endif