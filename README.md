## Shader 代码

使用HLSL语法制作一些Unity Shader代码，避免以后重复制作

> [!IMPORTANT]
>  - Unity版本： URP 2022.3.9f
>  - 测试环境： Win DX11


### 具体效果

  | 名称      | 效果     | 描述       |
  |------------|------------|------------|
  |  [00_HLSLShader](00_Base/Shader/00_HLSLShader.shader) | <img src="00_Base/00.png" width="75%">    | 基础Shader，只转换HLSL语法    |
  |  [01_HLSLShader](00_Base/Shader/01_HLSLShader.shader)   | <img src="00_Base/01.gif" width="75%">    | 基础Shader，增加关键字枚举类型切换   |
  |  [01_Lanbert](01_LightingModel/Shader/01_Lanbert.shader) | <img src="01_LightingModel/01_lanbert.png" width="75%"> | 漫反射，兰伯特光照模型|
  |  [01_HalfLanbert](01_LightingModel/Shader/01_HalfLanbert.shader) | <img src="01_LightingModel/01_HalfLanbert.png" width="75%"> | 漫反射，半兰伯特光照模型|
  |  [01_Phong](01_LightingModel/Shader/01_Phong.shader) | <img src="01_LightingModel/01_Phong.png" width="75%"> | |
  |  [01_BlinnPhong](01_LightingModel/Shader/01_BlinnPhong.shader) | <img src="01_LightingModel/01_BlinnPhong.png" width="75%"> | |
