
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库

TEXTURE2D(_CameraDepthTexture);                             // 获取深度贴图  
SAMPLER(sampler_CameraDepthTexture);                        // 深度贴图采样器

SAMPLER(_CameraOpaqueTexture);                   // 获取场景颜色贴图

float CustomSampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;           
}


// ======================================================================================================================================

half3 ScenePosition(half2 _UV, float3 WorldSpacePosition, float4 ScreenPosition)
{

    // 计算视角向量
    half3 viewDir = -1 * (_WorldSpaceCameraPos.xyz - GetAbsolutePositionWS(WorldSpacePosition));


    // 获取屏幕坐标
    half4 screenPosition = ScreenPosition;
    // 获取UV坐标
    half2 uv = _UV;
    float screenDepth = CustomSampleSceneDepth(uv);        //计算屏幕深度 是非线性


    // 提取屏幕坐标的分量
    half screenX = screenPosition.x;
    half screenY = screenPosition.y;
    half screenZ = screenPosition.z;
    half screenW = screenPosition.w;

    half3 dividedViewVector = viewDir / screenW;


    // 计算场景深度
    half sceneDepth = LinearEyeDepth(screenDepth, _ZBufferParams);

    // 计算场景位置
    half3 scenePos = dividedViewVector * sceneDepth;

    // 获取摄像机位置
    half3 cameraPos = _WorldSpaceCameraPos;



    // 输出结果
    return scenePos = scenePos + cameraPos;
}


float4 ComputeScreenPos(float4 pos, float projectionSign)                          //齐次坐标变换到屏幕坐标
{
    float4 o = pos * 0.5f;
    o.xy = float2(o.x,o.y * projectionSign) + o.w;             
    o.zw = pos.zw;
    return o;
}

//输入世界空间   WorldPos   
float GetDepthFade(float3 WorldPos, float Distance)
{
    float4 posCS = TransformWorldToHClip(WorldPos);                                            //转换成齐次坐标   
    float4 ScreenPosition = ComputeScreenPos(posCS, _ProjectionParams.x);                      //齐次坐标系下的屏幕坐标值
    //从齐次坐标变换到屏幕坐标， x,y的分量 范围在[-w,w]的范围   _ProjectionParams 用于在使用翻转投影矩阵时（此时其值为-1.0）翻转y的坐标值。
    //这里
    float screenDepth = CustomSampleSceneDepth(ScreenPosition.xy / ScreenPosition.w);        //计算屏幕深度 是非线性

    float EyeDepth = LinearEyeDepth(screenDepth,_ZBufferParams);                            //深度纹理的采样结果转换到视角空间下的深度值
    return saturate((EyeDepth - ScreenPosition.w)/ Distance);                               //使用视角空间下所有深度 减去模型顶点的深度值
}

void ComputeDepthFade(float2 UV, float Distance, float3 WorldSpacePosition, float4 ScreenPosition , out float ExponentialFade, out float LinearFade)
{

    // 计算场景位置
    float3 worldPos = WorldSpacePosition;

    // 计算屏幕位置
    float3 screenPos = ScenePosition(UV, worldPos, ScreenPosition);

    
    // 位置g通道
    float g = (worldPos - screenPos).g;


    // 计算距离
    float distance = -1 * g;
    distance /= Distance;


    // 返回结果
    ExponentialFade = saturate(exp(distance));
    LinearFade = saturate(g / Distance);
}

float Fresnel(float3 Normal, float3 ViewDir, half Power)
{
    return pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
}


float4 ScreenColor(float4 positionCS, float2 uv)                                               //获取屏幕颜色
{
    float2 screenUV = (positionCS.xy / _ScreenParams.xy);
    return tex2D(_CameraOpaqueTexture,  uv);
}

float2 PanningUV(float2 uv, float Tiling, float direction, float speed, float2 Offset)                 //UV平移
{
    float2 TiledUV = uv * Tiling;

    //  Direction 转换为弧度并计算其余弦和正弦值
    float Radians = (direction * 2 - 1) * 3.141593;
    float Cosine = cos(Radians);
    float Sine = sin(Radians);

    float2 DirectionVector = normalize(float2(Cosine, Sine));
    // 计算速度乘以时间
    float ScaledTime = _Time.y * speed;
    // 计算平移量
    float2 Translation = DirectionVector * ScaledTime;
    // 输出 UV 加上平移量和 Offset
    return TiledUV + Translation + Offset;
}

float4 Overlay(float4 base, float4 overlay, float blend)                                                  //叠加
{

    // 分解覆盖颜色的 alpha 分量并进行饱和处理
    float overlayAlpha = saturate(overlay.a);

    // 执行混合操作
    float4 blendOverwrite = lerp(base, overlay, overlayAlpha);
    float4 blendLinearDodge = lerp(base, base + blend, overlayAlpha);

    // 在混合结果之间进行线性插值
    float4 lerpedResult = lerp(blendOverwrite, blendLinearDodge, blend);

    // 设置输出
    return lerpedResult;
}

// 辅助函数：计算平铺和偏移
float2 TilingAndOffset(float2 uv, float2 tiling, float2 offset)
{
    return uv  * tiling + offset;
}


float2 Remap(half In, half2 InMinMax, half2 OutMinMax)
{
    float2 remap = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
    return remap;
}


half Comparison(float A, float B)
{
    return A >= B ? 1 : 0;
}


half4 Branch(half Predicate, half4 True, half4 False)
{
    half4 Out = Predicate != 0 ? True : False;

    return Out;
}


float2 DistortUV(float2 UV, float Amount)
{
    float time = _Time.y;
    
    UV.y += Amount * 0.01 * (sin(UV.x * 3.5 + time * 0.35) + sin(UV.x * 4.8 + time * 1.05) + sin(UV.x * 7.3 + time * 0.45)) / 3.0;
    UV.x += Amount * 0.12 * (sin(UV.y * 4.0 + time * 0.50) + sin(UV.y * 6.8 + time * 0.75) + sin(UV.y * 11.3 + time * 0.2)) / 3.0;
    UV.y += Amount * 0.12 * (sin(UV.x * 4.2 + time * 0.64) + sin(UV.x * 6.3 + time * 1.65) + sin(UV.x * 8.2 + time * 0.45)) / 3.0;

    return UV;
}

float3 GerstnerWave(float3 position, float steepness, float wavelength, float speed, float direction, inout float3 tangent, inout float3 binormal)
{
    // 将方向调整到[-1, 1]范围
    direction = direction * 2 - 1;
    
    // 计算方向向量d，使用正弦和余弦函数将方向转化为二维向量
    float2 d = normalize(float2(cos(3.14 * direction), sin(3.14 * direction)));
    
    // 计算波数k，k = 2π / 波长
    float k = 2 * 3.14 / wavelength;
    
    // 计算相位f，f = k * (d与position.xz的点积 + speed * _Time.y)
    float f = k * (dot(d, position.xz) + speed * _Time.y);
    
    // 计算波的幅度a，a = 陡度 / k
    float a = steepness / k;

    // 更新切线向量tangent
    tangent += float3(
        -d.x * d.x * (steepness * sin(f)),  // x方向的分量
        d.x * (steepness * cos(f)),         // y方向的分量
        -d.x * d.y * (steepness * sin(f))   // z方向的分量
    );

    // 更新双切线向量binormal
    binormal += float3(
        -d.x * d.y * (steepness * sin(f)),  // x方向的分量
        d.y * (steepness * cos(f)),         // y方向的分量
        -d.y * d.y * (steepness * sin(f))   // z方向的分量
    );

    // 返回波形位移
    return float3(
        d.x * (a * cos(f)),  // x方向的位移
        a * sin(f),          // y方向的位移
        d.y * (a * cos(f))   // z方向的位移
    );
}

float3 NormalBlend(float3 A, float3 B)
{
    return SafeNormalize(float3(A.rg + B.rg, A.b * B.b));
}


float LightingSpecular(float3 L, float3 N, float3 V, float smoothness)
{
    float3 H = SafeNormalize(float3(L) + float3(V));
    float NdotH = saturate(dot(N, H));
    return pow(NdotH, smoothness);
}

float MainLighting(float3 normalWS, float3 positionWS, float3 viewWS, float smoothness)
{
    float specular = 0.0;

    #ifndef SHADERGRAPH_PREVIEW
    smoothness = exp2(10 * smoothness + 1);
        
    normalWS = normalize(normalWS);
    viewWS = SafeNormalize(viewWS);

    Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS));
    specular = LightingSpecular(mainLight.direction, normalWS, viewWS, smoothness);
    #endif
    return specular;
}


float3 AdditionalLighting(float3 normalWS, float3 positionWS, float3 viewWS, float smoothness, float hardness)
{
    float3 specular = 0;

    #ifndef SHADERGRAPH_PREVIEW
    smoothness = exp2(10 * smoothness + 1);

    normalWS = normalize(normalWS);
    viewWS = SafeNormalize(viewWS);

    // additional lights
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, positionWS);
        float3 attenuatedLight = light.color * light.distanceAttenuation * light.shadowAttenuation;
        
        float specular_soft = LightingSpecular(light.direction, normalWS, viewWS, smoothness);
        float specular_hard = smoothstep(0.005,0.01,specular_soft);
        float specular_term = lerp(specular_soft, specular_hard, hardness);

        specular += specular_term * attenuatedLight;
    }
    #endif

    return specular;
}