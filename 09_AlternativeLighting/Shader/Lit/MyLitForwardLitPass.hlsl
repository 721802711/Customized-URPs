#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"    // 光照
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Lit/MyLitCommon.hlsl"


struct Attributes                         // 输入结构体
{
    float3 positionOS : POSITION;           //  输入顶点信息
    float3 normalOS : NORMAL;               //  输入法线信息
    float4 tangentOS : TANGENT;             //  输入切线信息
    float2 uv : TEXCOORD0;                  //  输入UV信息
};

struct Interpolators
{
    float4 positionCS : SV_POSITION;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;
    float2 uv : TEXCOORD0;
};

Interpolators vert(Attributes input)
{
    Interpolators output;      // 声明变量
    VertexPositionInputs  PositionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = PositionInputs.positionCS;                          //获取齐次坐标信息
    output.positionWS = PositionInputs.positionWS;                          // 顶点世界空间

    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);   // 转换空间
    output.normalWS = normInputs.normalWS;                                   // 输出 法线
    output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);                                 // 输出 切线

    output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
    return output;             // 输出
}

float4 frag(Interpolators input 
    #ifdef _DOUBLE_SIDED_NORMALS
        , FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC
    #endif
    ) : SV_TARGET {



    float3 normalWS = input.normalWS;
    
#ifdef _DOUBLE_SIDED_NORMALS
    normalWS *= IS_FRONT_VFACE(frontFace, 1, -1);
#endif


    float3 positionWS = input.positionWS;
    // 获取世界空间的视角向量
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
    float3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, normalWS, viewDirWS);   
    // 视差贴图
    float2 uv = input.uv;
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _ParallaxStrength, uv);



#ifdef _NORMALMAP
    // 法线贴图
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalStrength);
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, input.tangentWS.xyz, input.tangentWS.w);   // 切线空间转换到世界空间
    normalWS = normalize(TransformTangentToWorld(normalTS.xyz, tangentToWorld));
#else
    float3 normalTS = float3(0, 0, 1);
    normalWS = normalize(normalWS);
#endif
    float smoothnessSample = SAMPLE_TEXTURE2D(_SmoothnessMask, sampler_SmoothnessMask, uv).r * _Smoothness;

    // 表面输入数据
    InputData lightingInput = (InputData)0;
    lightingInput.normalWS   = normalWS;
    lightingInput.positionWS = positionWS;
    lightingInput.viewDirectionWS = viewDirWS; 
    // 计算阴影
    lightingInput.shadowCoord = TransformWorldToShadowCoord(positionWS);     
#if UNITY_VERSION >= 202120
    lightingInput.positionCS = input.positionCS;
    lightingInput.tangentToWorld = tangentToWorld;   // 输入切线空间转换到世界空间
#endif


    // 颜色贴图
    float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
    TestAlphaClip(colorSample);


    // 片元输入数据
    SurfaceData surfaceInput = (SurfaceData)0;
    surfaceInput.albedo = colorSample.rgb * _ColorTint.rgb;
    surfaceInput.alpha  = colorSample.a * _ColorTint.a;

#ifdef _SPECULAR_SETUP
    surfaceInput.specular = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv).rgb * _SpecularTint;
    surfaceInput.metallic = 0;
#else
    surfaceInput.specular = 1;
    surfaceInput.metallic = SAMPLE_TEXTURE2D(_MetalnessMask, sampler_MetalnessMask, uv).r * _Metalness;
#endif
    surfaceInput.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).rgb * _EmissionTint;
    surfaceInput.clearCoatMask = SAMPLE_TEXTURE2D(_ClearCoatMask, sampler_ClearCoatMask, uv).r * _ClearCoatStrength;
    surfaceInput.clearCoatSmoothness = SAMPLE_TEXTURE2D(_ClearCoatSmoothnessMask, sampler_ClearCoatSmoothnessMask, uv).r * _ClearCoatSmoothness;

    surfaceInput.normalTS = normalTS;             // 输入法线贴图


#ifdef _ROUGHNESS_SETUP
    smoothnessSample = 1 - smoothnessSample;
#endif
    surfaceInput.smoothness = smoothnessSample;


    return UniversalFragmentPBR(lightingInput, surfaceInput);
}