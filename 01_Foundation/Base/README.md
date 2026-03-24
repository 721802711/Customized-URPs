# Foundation Base - 基础Shader框架

本目录包含 URP Shader 开发的基础框架、模板和工具。是所有自定义 Shader 开发的起点。

## 📁 目录内容

- **Shader/** - Shader 源代码文件
  - `Foundation_Default.shader` -  HLSLINCLUDE架构，支持多Pass
  - `Foundation_Keyword.shader` - 关键字使用示例
  - `Foundation_Library.shader` - HLSL 函数库使用示例
  - `Foundation_Simple.shader` - 基础简单Shader
- **Material/** - 示例材质文件
- **Textures/** - 测试纹理
- **Models/** - 测试模型
- **Scene/** - 示例场景

## 🎯 一、基础 Shader 框架

### 1. Shader 基本结构

```hlsl
Shader "Foundation/Base/Default"
{
    Properties
    {
        _MainTex ("主纹理", 2D) = "white" {}
        _Color ("颜色", Color) = (1, 1, 1, 1)
    
    }
  
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        LOD 100

        // HLSLINCLUDE: 所有Pass共享的代码
        HLSLINCLUDE
    
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS : TEXCOORD1;
            float2 uv : TEXCOORD0;
        };
    
        ENDHLSL

        // Pass 1: ForwardLit (主渲染)
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
        
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            Varyings vert(Attributes input)
            {
                Varyings output;
            
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;

            
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInputs.normalWS;
            
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
            
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
            
                finalColor *= _Color;
            
                return finalColor;
            }
        
            ENDHLSL
        }

    }
  
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
}
```

### 2. 关键组成部分

#### Properties 块

定义材质面板中可调整的属性：

```hlsl
Properties
{
    _MainTex ("主纹理", 2D) = "white" {}
    _Color ("颜色", Color) = (1,1,1,1)
    _Float ("浮点数", Float) = 1.0
    _Range ("范围值", Range(0,1)) = 0.5
}
```

#### SubShader Tags

指定渲染管线和类型：

```hlsl
Tags 
{ 
    "RenderType"="Opaque"              // 渲染类型：Opaque/Transparent/Background
    "RenderPipeline"="UniversalPipeline"  // 渲染管线：URP
    "Queue"="Geometry"                  // 渲染队列
}
```

#### Pass 结构

每个 Pass 是一次渲染过程：

```hlsl
Pass
{
    Name "ForwardLit"                    // Pass 名称（可选）
    Tags { "LightMode" = "UniversalForward" }  // 光照模式
  
    // 渲染状态设置
    Cull Back          // 剔除：Back/Front/Off
    ZWrite On          // 深度写入
    ZTest LEqual       // 深度测试
    Blend One Zero     // 混合模式
  
    HLSLPROGRAM
    // Shader 代码
    ENDHLSL
}
```

#### 顶点和片元着色器

```hlsl
HLSLPROGRAM
#pragma vertex vert      // 顶点着色器函数
#pragma fragment frag    // 片元着色器函数

// 顶点着色器输入
struct Attributes
{
    float4 positionOS : POSITION;    // 对象空间位置
    float3 normalOS : NORMAL;        // 对象空间法线
    float2 uv : TEXCOORD0;           // UV 坐标
};

// 片元着色器输入
struct Varyings
{
    float4 positionCS : SV_POSITION; // 裁剪空间位置
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;     // 世界空间法线
};

Varyings vert(Attributes input) { ... }
half4 frag(Varyings input) : SV_Target { ... }

ENDHLSL
```

---

## 🔑 二、Shader 中关键字使用

关键字（Shader Keywords）用于创建 Shader 变体，实现条件编译和功能开关。

### 1. 定义关键字属性

在 `Properties` 块中定义：

```hlsl
Properties
{
    _MainTex ("Texture", 2D) = "white" {}
    _Color ("Tint Color", Color) = (1,1,1,1)
  
    // 枚举关键字：生成多个互斥选项
    [KeywordEnum(None, Green, Red)] _BlendMode ("混合模式", Float) = 0
  
    // 开关关键字：生成开/关两个状态
    [Toggle] _EnableEffect ("启用效果", Float) = 0
  
    // 自定义关键字名称
    [Toggle(CUSTOM_FEATURE)] _CustomFeature ("自定义功能", Float) = 0
}
```

### 2. 声明和使用关键字

#### 方式一：使用 #pragma shader_feature

```hlsl
HLSLPROGRAM
#pragma vertex vert
#pragma fragment frag

// KeywordEnum：使用 multi_compile 编译所有变体
#pragma multi_compile _BLENDMODE_NONE _BLENDMODE_GREEN _BLENDMODE_RED

// Toggle：使用 shader_feature 只编译使用的变体
#pragma shader_feature _ENABLEEFFECT_ON

// 自定义关键字
#pragma shader_feature CUSTOM_FEATURE

half4 frag(Varyings input) : SV_Target
{
    half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
  
    // KeywordEnum 示例：混合模式
    #if _BLENDMODE_GREEN
        color.rgb = half3(0.0, 1.0, 0.0);  // 纯绿色
    #elif _BLENDMODE_RED
        color.rgb = half3(1.0, 0.0, 0.0);  // 纯红色
    #endif
    // _BLENDMODE_NONE 不做处理
  
    // Toggle 示例：启用效果（颜色反转混合）
    #ifdef _ENABLEEFFECT_ON
        color.rgb = lerp(color.rgb, 1.0 - color.rgb, 0.3);
    #endif
  
    // 自定义关键字示例（红色调）
    #ifdef CUSTOM_FEATURE
        color.rgb *= float3(1, 0.5, 0.5);
    #endif
  
    return color;
}
ENDHLSL
```

#### 方式二：使用 #pragma multi_compile

```hlsl
// multi_compile 编译所有变体（适用于全局关键字或枚举关键字）
#pragma multi_compile _BLENDMODE_NONE _BLENDMODE_GREEN _BLENDMODE_RED
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

// 注意：KeywordEnum 推荐使用 multi_compile，确保所有变体都被编译
// shader_feature 只会编译被材质使用的变体，可能导致运行时切换失效
```

### 3. KeywordEnum 工作原理

```hlsl
// 属性定义
[KeywordEnum(Up, Down, Left, Right)] _Direction ("方向", Float) = 0

// 自动生成的关键字：
// _DIRECTION_UP
// _DIRECTION_DOWN
// _DIRECTION_LEFT
// _DIRECTION_RIGHT

// 在 Shader 中声明
#pragma shader_feature _DIRECTION_UP _DIRECTION_DOWN _DIRECTION_LEFT _DIRECTION_RIGHT

// 使用示例
#if defined(_DIRECTION_UP)
    offset = float2(0, 1);
#elif defined(_DIRECTION_DOWN)
    offset = float2(0, -1);
#elif defined(_DIRECTION_LEFT)
    offset = float2(-1, 0);
#elif defined(_DIRECTION_RIGHT)
    offset = float2(1, 0);
#endif
```

### 4. 关键字命名规则

- **Toggle 关键字**：自动添加 `_ON` 后缀
  - `[Toggle] _Feature` → `_FEATURE_ON`
- **KeywordEnum 关键字**：格式为 `_属性名_枚举值`
  - `[KeywordEnum(A,B)] _Mode` → `_MODE_A`, `_MODE_B`
- **自定义关键字**：使用指定名称
  - `[Toggle(MY_KEYWORD)] _Feature` → `MY_KEYWORD`

### 5. 完整示例：Foundation_Keyword.shader

`Foundation_Keyword.shader` 提供了三种关键词类型的完整示例：

```hlsl
Shader "Foundation/Base/Keyword"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint Color", Color) = (1,1,1,1)
        
        [KeywordEnum(None, Green, Red)] _BlendMode ("混合模式", Float) = 0
        [Toggle] _EnableEffect ("启用效果", Float) = 0
        [Toggle(CUSTOM_FEATURE)] _CustomFeature ("自定义功能", Float) = 0
    }
    
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 声明关键字
            #pragma multi_compile _BLENDMODE_NONE _BLENDMODE_GREEN _BLENDMODE_RED
            #pragma shader_feature _ENABLEEFFECT_ON
            #pragma shader_feature CUSTOM_FEATURE
            
            // ... 顶点着色器 ...
            
            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                
                // 枚举关键字效果
                #if _BLENDMODE_GREEN
                    col.rgb = half3(0.0, 1.0, 0.0);
                #elif _BLENDMODE_RED
                    col.rgb = half3(1.0, 0.0, 0.0);
                #endif
                
                // Toggle 关键字效果
                #ifdef _ENABLEEFFECT_ON
                    col.rgb = lerp(col.rgb, 1.0 - col.rgb, 0.3);
                #endif
                
                // 自定义关键字效果
                #ifdef CUSTOM_FEATURE
                    col.rgb *= float3(1, 0.5, 0.5);
                #endif
                
                return col;
            }
            ENDHLSL
        }
    }
}
```

**效果说明**：
- **None**：显示原始纹理颜色
- **Green**：覆盖为纯绿色
- **Red**：覆盖为纯红色
- **启用效果**：与反转颜色混合 30%
- **自定义功能**：应用红色调（保持红色通道，绿蓝通道减半）

### 6. 最佳实践

```hlsl
// ✅ 推荐：KeywordEnum 使用 multi_compile 确保所有变体可用
#pragma multi_compile _MODE_NONE _MODE_A _MODE_B

// ✅ 推荐：Toggle 使用 shader_feature 减少包体
#pragma shader_feature _FEATURE_ON

// ✅ 推荐：枚举关键字用于互斥选项
[KeywordEnum(Low, Medium, High)] _Quality ("质量", Float) = 1

// ⚠️ 注意：避免过多关键字组合
// 3 个 shader_feature = 2³ = 8 个变体
// 4 个 shader_feature = 2⁴ = 16 个变体

// ✅ 推荐：相关功能合并为枚举
[KeywordEnum(Off, Simple, Advanced)] _EffectMode ("效果模式", Float) = 0
```

### 7. shader_feature vs multi_compile

| 特性 | shader_feature | multi_compile |
|------|----------------|---------------|
| **编译变体** | 只编译材质使用的变体 | 编译所有可能的变体 |
| **包体大小** | 更小（推荐） | 更大 |
| **运行时切换** | 仅限预编译的变体 | 所有变体都可切换 |
| **适用场景** | 材质级特性开关 | 全局关键字、质量设置 |
| **示例** | Toggle特性 | KeywordEnum、光照关键字 |

**选择建议**：
- **材质特性**：使用 `shader_feature`（如 _NORMALMAP_ON）
- **枚举选项**：使用 `multi_compile`（如 _BLENDMODE_*）
- **全局设置**：使用 `multi_compile`（如 _MAIN_LIGHT_SHADOWS）

## 📚 三、HLSL 函数库使用方法

### 1. 创建 HLSL 函数库文件

创建 `.hlsl` 文件（如 `Foundation_LitPass.hlsl`）：

```hlsl
#ifndef FOUNDATION_LIT_PASS_INCLUDED
#define FOUNDATION_LIT_PASS_INCLUDED

// 引入 URP 核心库
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// ========== 结构体定义 ==========
struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
};

// ========== 纹理和变量声明 ==========
TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST;
    float4 _Color;
CBUFFER_END

// ========== 工具函数 ==========

// UV 旋转函数
float2 RotateUV(float2 uv, float rotation)
{
    float cosAngle = cos(rotation);
    float sinAngle = sin(rotation);
    float2 center = float2(0.5, 0.5);
    uv -= center;
    float2 rotatedUV;
    rotatedUV.x = uv.x * cosAngle - uv.y * sinAngle;
    rotatedUV.y = uv.x * sinAngle + uv.y * cosAngle;
    return rotatedUV + center;
}

// 简单光照计算
half3 CalculateSimpleLighting(float3 normalWS, float3 positionWS)
{
    Light mainLight = GetMainLight();
    half3 lightDir = normalize(mainLight.direction);
    half NdotL = saturate(dot(normalWS, lightDir));
    return mainLight.color * NdotL;
}

// Fresnel 效果
half CalculateFresnel(float3 normalWS, float3 viewDirWS, half power)
{
    half fresnel = 1.0 - saturate(dot(normalWS, viewDirWS));
    return pow(fresnel, power);
}

// ========== 顶点着色器 ==========
Varyings vert(Attributes input)
{
    Varyings output;
  
    // 空间转换
    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = positionInputs.positionCS;
    output.positionWS = positionInputs.positionWS;
  
    // 法线转换
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
    output.normalWS = normalInputs.normalWS;
  
    // UV 变换
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
  
    return output;
}

// ========== 片元着色器 ==========
half4 frag(Varyings input) : SV_Target
{
    // 采样纹理
    half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
  
    // 计算光照
    half3 lighting = CalculateSimpleLighting(input.normalWS, input.positionWS);
  
    // 最终颜色
    half4 finalColor = texColor * _Color;
    finalColor.rgb *= lighting;
  
    return finalColor;
}

#endif // FOUNDATION_LIT_PASS_INCLUDED
```

### 2. 在 Shader 中引用函数库

**方法一：相对路径引用**（推荐用于同目录）

```hlsl
Shader "Foundation/Base/Library"
{
    Properties { ... }
  
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
  
            // 使用相对路径引用同目录下的 .hlsl 文件
            #include "./Foundation_LitPass.hlsl"
  
            ENDHLSL
        }
    }
}
```

**方法二：绝对路径引用**

```hlsl
// 从 Assets 根目录开始的完整路径
#include "Assets/Customized-URPs/01_Foundation/Base/Shader/Foundation_LitPass.hlsl"
```

**方法三：使用 Packages 路径**（引用 URP 内置库）

```hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
```

### 3. HLSL Include 头文件保护

始终使用头文件保护避免重复包含：

```hlsl
#ifndef MY_CUSTOM_LIBRARY_INCLUDED
#define MY_CUSTOM_LIBRARY_INCLUDED

// 你的函数库代码...

#endif // MY_CUSTOM_LIBRARY_INCLUDED
```

### 4. 常用 URP Shader 库

```hlsl
// 核心库（必须）
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// 光照计算
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// 阴影
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// 空间转换
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

// 颜色工具
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

// 通用输入（Unity 内置变量）
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

// 表面数据
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
```

### 5. 函数库组织建议

```
Shader/
├── Foundation_Default.shader          # 基础模板
├── Foundation_Keyword.shader          # 关键字示例
├── Foundation_Library.shader          # 函数库使用示例
├── Foundation_LitPass.hlsl           # 光照 Pass 函数库
├── Foundation_Common.hlsl            # 通用工具函数
└── Foundation_Lighting.hlsl          # 自定义光照函数
```

### 6. 完整使用示例

```hlsl
Shader "Foundation/Base/Example"
{
    Properties
    {
        _MainTex ("主纹理", 2D) = "white" {}
        _Color ("颜色", Color) = (1,1,1,1)
        [KeywordEnum(None, Add, Multiply)] _BlendMode ("混合模式", Float) = 0
        [Toggle(USE_FRESNEL)] _UseFresnel ("使用菲涅尔", Float) = 0
    }
  
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
  
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
  
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
  
            // 声明关键字
            #pragma shader_feature _BLENDMODE_NONE _BLENDMODE_ADD _BLENDMODE_MULTIPLY
            #pragma shader_feature USE_FRESNEL
  
            // 引用函数库
            #include "./Foundation_LitPass.hlsl"
            // 如果需要额外功能，可以在这里添加
  
            // vert 和 frag 函数已在 Foundation_LitPass.hlsl 中定义
  
            ENDHLSL
        }
    }
}
```

## 📖 学习资源

### 示例文件

- **Foundation_Default.shader** - 最基础的 URP Shader 模板
- **Foundation_Keyword.shader** - 关键字使用完整示例
- **Foundation_Library.shader** - HLSL 函数库引用示例
- **Foundation_LitPass.hlsl** - 可复用的函数库实现

### 推荐学习顺序

1. 📝 阅读 `Foundation_Default.shader`，理解基本结构
2. 🔑 学习 `Foundation_Keyword.shader`，掌握关键字用法
3. 📚 研究 `Foundation_Library.shader` 和 `Foundation_LitPass.hlsl`，学习代码复用
4. 🎨 在 Unity 中创建材质，实践调整参数
5. 🔧 基于模板创建自己的 Shader

## 💡 最佳实践

**更新时间**：2026年2月13日
**适用版本**：Unity 2021.3+ / URP 12.0+
