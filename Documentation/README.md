# VFX Shader Library - 视觉特效着色器库

[![Unity](https://img.shields.io/badge/Unity-2021.3%2B-blue.svg)](https://unity3d.com/get-unity/download)
[![URP](https://img.shields.io/badge/URP-12.0%2B-green.svg)](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@latest)

一个全面的、模块化的Unity URP着色器库，专为VFX美术和技术美术设计。

## 📚 目录结构

```
VFX-Shader-Library/
├── 01_Foundation/              # 基础架构
├── 02_Surface/                 # 表面处理
├── 03_Lighting/                # 光照系统
├── 04_Material/                # 材质库
├── 05_VFX/                     # 视觉特效
├── 06_Environment/             # 环境系统
├── 07_Scene/                   # 场景功能
├── 08_Post/                    # 后处理
├── 09_2D/                      # 2D着色器
├── 10_Utilities/               # 工具类
├── 11_Advanced/                # 高级技术
├── 12_ShaderGraph/             # ShaderGraph文件
├── Scripts/                    # 脚本支持
└── Documentation/              # 文档
```

## 🎯 特性

### 核心功能
- ✅ **模块化设计**：所有Shader按功能分类，易于查找和使用
- ✅ **URP优化**：专为Universal Render Pipeline优化
- ✅ **完整文档**：每个着色器都有详细说明和使用示例
- ✅ **性能友好**：针对移动端和PC端进行优化
- ✅ **易于扩展**：清晰的代码结构，便于自定义修改

### 包含内容

#### 01_Foundation - 基础架构
- 基础Shader模板
- 常用光照模型
- 数学工具函数库

#### 02_Surface - 表面处理
- 法线贴图和凹凸贴图
- 视差映射（POM、陡峭视差等）
- 曲面细分技术

#### 03_Lighting - 光照系统
- 标准光照（Lambert、Phong、Blinn-Phong）
- PBR光照（标准PBR、皮肤SSS、各向异性）
- NPR渲染（卡通、赛璐珞、渐变）
- 自定义阴影和多光源支持

#### 04_Material - 材质库
- **角色材质**：皮肤、头发、布料、金属
- **环境材质**：水面、玻璃、宝石、植被、地形
- **道具材质**：武器、通用物体
- **特殊材质**：全息投影、力场、幽灵效果

#### 05_VFX - 视觉特效
- **粒子效果**：标准、叠加、扭曲、自定义粒子
- **溶解效果**：基础溶解、边缘颜色、方向性溶解
- **扭曲效果**：空气扭曲、热浪、世界空间扭曲
- **发光效果**：辉光、边缘光、菲涅尔光
- **遮罩系统**：UV遮罩、球形遮罩、方向遮罩
- **动画系统**：UV动画、顶点动画、噪波、序列帧

#### 06_Environment - 环境系统
- 大气效果（雾效、高度雾、体积雾）
- 天空系统（天空盒、渐变天空、程序化天空）
- 反射系统（Cubemap、MatCap、平面反射、SSR）

#### 07_Scene - 场景功能
- 贴花系统
- 投影技术
- 遮挡处理
- 透明度控制（Alpha混合、Alpha测试、软粒子）

#### 08_Post - 后处理
- 模糊效果
- 调色分级
- 扭曲效果
- 故障效果
- 径向模糊
- 自定义后处理

#### 09_2D - 2D着色器
- **精灵效果**：外描边、内发光、溶解、调色
- **UI特效**：渐变、遮罩、扭曲
- **2D特效**：阴影、全息、故障

#### 10_Utilities - 工具类
- UV操作（变换、滚动、旋转、平铺）
- 数据可视化（法线显示、UV显示、空间转换）
- 调试工具（线框、过度绘制、Mipmap）
- 辅助工具（取色器、网格显示）

#### 11_Advanced - 高级技术
- 计算着色器
- 光线步进（Ray Marching）
- 屏幕空间技术
- 自定义渲染Pass

#### 12_ShaderGraph - 可视化编辑
- 预制模板
- 子图库
- 示例图

## 🚀 快速开始

### 环境要求
- Unity 2021.3 或更高版本
- Universal Render Pipeline 12.0+
- Shader Graph（已包含在URP中）

### 安装步骤
1. 将 `Customized-URPs` 文件夹放入项目的 `Assets` 目录
2. 确保项目已配置URP
3. 在Project窗口中浏览相应类别查找所需Shader

### 基础使用
1. 创建Material
2. 在Shader下拉菜单中选择对应的Shader
3. 调整参数以达到想要的效果
4. 应用到网格或粒子系统

## 📖 文档导航

- [迁移指南](MIGRATION_GUIDE.md) - 从旧版本迁移
- [教程目录](Tutorials/) - 分步教程
- [示例场景](Examples/) - 可运行的示例

## 🎨 使用示例

### 创建溶解效果
```csharp
// 在Material Inspector中
Shader: VFX/Dissolve/BasicDissolve
- 设置 Dissolve Texture
- 调整 Dissolve Amount (0-1)
- 设置 Edge Color 和 Edge Width
```

### 创建卡通渲染
```csharp
// 在Material Inspector中
Shader: Lighting/NPR/Toon
- 设置 Color Ramp Texture
- 调整 Shadow Threshold
- 配置 Rim Light 参数
```

### 创建水面材质
```csharp
// 在Material Inspector中
Shader: Material/Environment/Water/StylizedWater
- 设置 Normal Map 和 Flow Map
- 调整 Wave Parameters
- 配置 Reflection 和 Refraction
```

## 🔧 自定义开发

### 创建新Shader
1. 参考 `01_Foundation/Base/` 中的模板
2. 按照现有命名和结构规范
3. 添加详细注释
4. 放入合适的分类目录

### 代码规范
- 使用清晰的变量命名
- 添加属性描述和范围
- 优化性能关键代码
- 提供移动端版本（如需要）

## 📊 性能指南

### 移动端优化
- 使用 `half` 而非 `float` 精度
- 减少纹理采样次数
- 避免复杂的数学运算
- 使用LOD系统

### PC端优化
- 合理使用高级特性
- 控制粒子数量
- 优化后处理堆栈
- 使用GPU Instancing

## 🤝 贡献指南

欢迎贡献新的Shader或改进现有代码！

1. Fork项目
2. 创建特性分支
3. 提交改动
4. 发起Pull Request

## 📝 更新日志

### v2.0 (2026-02-13)
- ✨ 重构目录结构
- ✨ 新增系统化分类
- 📚 完善文档
- 🔧 优化性能

### v1.0
- 🎉 初始版本发布

## 🐛 问题反馈

遇到问题？请通过以下方式反馈：
- 提交Issue
- 联系技术美术团队
- 查阅FAQ文档

## 📄 许可证

本项目仅供内部使用。

## 👥 贡献者

感谢所有为本项目做出贡献的开发者！

---

**技术美术团队**  
最后更新：2026年2月13日
