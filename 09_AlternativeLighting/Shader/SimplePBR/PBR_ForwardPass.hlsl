#ifndef PBR_FORWARDPASS_INCLUDED
#define PBR_FORWARDPASS_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"           
#include "PBR_Common.hlsl"
#include "PBR_Functions.hlsl"



struct appdata
{
    float4 positionOS : POSITION;                     //输入顶点
    float4 normalOS : NORMAL;                         //输入法线
    float2 texcoord : TEXCOORD0;                      //输入uv信息
    float4 tangentOS : TANGENT;                       //输入切线
    
    #if LIGHTMAP_ON
        float2 staticLightmapUV : TEXCOORD1;
    #endif
};

struct v2f
{
    float2 uv : TEXCOORD0;                            //输出uv
    float4 positionCS : SV_POSITION;                  //齐次位置
    float3 positionWS : TEXCOORD1;                    //世界空间下顶点位置信息
    float3 normalWS : NORMAL;                         //世界空间下法线信息
    float3 tangentWS : TANGENT;                       //世界空间下切线信息
    float3 BtangentWS : TEXCOORD2;                    //世界空间下副切线信息
    float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角
    
    #if LIGHTMAP_ON
        float2 staticLightmapUV : TEXCOORD4;
    #endif  
 
};

 
 v2f vert(appdata v)
{
    v2f o;
    o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTex);
    VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
    o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

    VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
    o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
    o.tangentWS.xyz = NormalInputs.tangentWS;                              //  获取世界空间下切线信息
    o.BtangentWS.xyz = NormalInputs.bitangentWS;                            //  获取世界空间下副切线信息

    o.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;   //  相机世界位置 - 世界空间顶点位置
    
    #if LIGHTMAP_ON
        OUTPUT_LIGHTMAP_UV(v.staticLightmapUV, unity_LightmapST, o.staticLightmapUV)
    #endif  
    
    return o;
}


half4 frag(v2f i) : SV_Target
{
    // ============================================================================================================================================================
    half4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex,sampler_DiffuseTex,i.uv);
    half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
    normal.g = lerp(normal.g,1-normal.g,_NormalInvertG);                                // 切换不同平台法线
    half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv);
    mask.g = lerp(mask.g, 1 - mask.g , _RoughnessInvert);                               // 粗糙度翻转

    half metallic = _Metallic * mask.r;
    half smoothness = _Roughness * mask.g;
    half ao = lerp(1,mask.b,_AO);
    half3 emissive = mask.a * _EmissivColor.rgb * _EmissivInt;
    half roughness = pow((1 - _Roughness),2);
    // ============================================================================================================================================================
    float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};            // 矩阵
    TBN = transpose(TBN);
    float3 norTS = UnpackNormalScale(normal, _NormalScale);                        // 使用变量控制法线的强度
    norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));                        // 规范化法线 

    half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));                           // 顶点法线和法线贴图融合 = 输出世界空间法线信息
    // ============================================================================================================================================================
    
    
    
    #if LIGHTMAP_ON
        half3 bakeGI = SampleLightmap(i.staticLightmapUV, N);
    #else
        half3 bakeGI = half3(0, 0, 0);
    #endif
    
    
    
    half3 PBRcolor = PBR(i.viewDirWS, N, i.positionWS, albedo.rgb, roughness, metallic, ao, smoothness, emissive, bakeGI);
    
    
    

#ifdef _ADDITIONALLIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for(int index = 0; index < pixelLightCount; index++)
    {

        Light light = GetAdditionalLight(index,i.positionWS);
        PBRcolor += PBRDirectLightResult(light,i.viewDirWS,N,albedo.rgb,roughness,metallic) * _LightInt;          // 多光源计算

    }

#endif

    return half4(PBRcolor.rgb,1);

}
#endif