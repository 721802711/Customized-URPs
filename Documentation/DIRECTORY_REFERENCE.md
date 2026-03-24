# 目录结构快速参考

## 📁 完整目录树

```
Customized-URPs/
│
├── 📂 01_Foundation/                    # 基础架构
│   ├── Base/                            # 基础Shader模板
│   ├── LightingModels/                  # 光照模型
│   └── MathUtilities/                   # 数学工具函数
│
├── 📂 02_Surface/                       # 表面处理
│   ├── Normal/                          # 法线相关
│   │   ├── BumpMapping/                 # 凹凸贴图
│   │   ├── NormalMapping/               # 法线贴图
│   │   └── DetailNormal/                # 细节法线
│   ├── Parallax/                        # 视差映射
│   │   ├── Simple/                      # 简单视差
│   │   ├── Steep/                       # 陡峭视差
│   │   ├── POM/                         # 视差遮挡映射
│   │   └── Relief/                      # 浮雕视差
│   └── Tessellation/                    # 曲面细分
│       ├── Flat/                        # 平面细分
│       ├── Phong/                       # Phong细分
│       ├── PN/                          # PN三角形细分
│       └── Displacement/                # 位移细分
│
├── 📂 03_Lighting/                      # 光照系统
│   ├── Standard/                        # 标准光照
│   │   ├── Lambert/                     # 兰伯特光照
│   │   ├── Phong/                       # 冯氏光照模型
│   │   └── BlinnPhong/                  # 布林冯光照模型
│   ├── PBR/                             # 基于物理的渲染
│   │   ├── StandardPBR/                 # 标准PBR
│   │   ├── ExtendedPBR/                 # 扩展PBR（多贴图）
│   │   ├── SkinPBR/                     # 皮肤PBR（次表面散射）
│   │   └── AnisotropicPBR/              # 各向异性PBR
│   ├── NPR/                             # 非真实感渲染
│   │   ├── Toon/                        # 卡通渲染
│   │   ├── Cel/                         # 赛璐珞着色
│   │   └── Ramp/                        # 渐变光照
│   ├── Shadows/                         # 阴影相关
│   │   ├── CustomShadows/               # 自定义阴影
│   │   ├── ShadowColor/                 # 阴影颜色
│   │   └── BakedShadows/                # 烘焙阴影
│   └── AdvancedLighting/                # 高级光照
│       ├── MultipleLights/              # 多光源支持
│       ├── CustomLit/                   # 自定义光照
│       └── FakeLighting/                # 假光照/艺术光照
│
├── 📂 04_Material/                      # 材质库
│   ├── Character/                       # 角色材质
│   │   ├── Skin/                        # 皮肤（SSS、眼球、虹膜）
│   │   ├── Hair/                        # 头发（各向异性高光）
│   │   ├── Cloth/                       # 布料
│   │   └── Metal/                       # 金属装备
│   ├── Environment/                     # 环境材质
│   │   ├── Water/                       # 水面
│   │   │   ├── StylizedWater/           # 风格化水面
│   │   │   ├── RealisticWater/          # 写实水面
│   │   │   └── DesktopWater/            # 桌面水面
│   │   ├── Glass/                       # 玻璃/透明材质
│   │   ├── Gem/                         # 宝石材质
│   │   ├── Foliage/                     # 植被材质
│   │   └── Terrain/                     # 地形材质
│   ├── Props/                           # 道具材质
│   │   ├── Weapon/                      # 武器材质
│   │   └── Objects/                     # 通用物体
│   └── Special/                         # 特殊材质
│       ├── Hologram/                    # 全息投影效果
│       ├── ForceField/                  # 力场效果
│       └── Ghost/                       # 幽灵/半透明效果
│
├── 📂 05_VFX/                           # 视觉特效
│   ├── Particles/                       # 粒子效果
│   │   ├── StandardParticle/            # 标准粒子Shader
│   │   ├── AdditiveParticle/            # 叠加粒子Shader
│   │   ├── DistortParticle/             # 扭曲粒子Shader
│   │   └── CustomParticle/              # 自定义粒子Shader
│   ├── Dissolve/                        # 溶解效果
│   │   ├── BasicDissolve/               # 基础溶解
│   │   ├── EdgeColor/                   # 边缘颜色溶解
│   │   ├── DirectionalDissolve/         # 方向性溶解
│   │   ├── PointDissolve/               # 点溶解（球形/径向）
│   │   └── AdvancedDissolve/            # 高级溶解（灰烬等）
│   ├── Distortion/                      # 扭曲效果
│   │   ├── AirDistortion/               # 空气扭曲
│   │   ├── HeatWave/                    # 热浪扭曲
│   │   └── WorldDistortion/             # 世界空间扭曲
│   ├── Emission/                        # 自发光效果
│   │   ├── Glow/                        # 辉光效果
│   │   ├── EdgeLight/                   # 边缘光/轮廓光
│   │   └── FresnelLight/                # 菲涅尔光
│   ├── Mask/                            # 遮罩效果
│   │   ├── UVMask/                      # UV空间遮罩
│   │   ├── SphereMask/                  # 球形遮罩
│   │   └── DirectionalMask/             # 方向遮罩
│   └── Animation/                       # 动画效果
│       ├── UVAnimation/                 # UV动画/滚动
│       ├── VertexAnimation/             # 顶点动画
│       ├── Noise/                       # 噪波动画
│       └── Sequence/                    # 序列帧动画
│
├── 📂 06_Environment/                   # 环境系统
│   ├── Atmosphere/                      # 大气效果
│   │   ├── Fog/                         # 基础雾效
│   │   ├── HeightFog/                   # 高度雾
│   │   └── VolumetricFog/               # 体积雾
│   ├── Sky/                             # 天空系统
│   │   ├── SkyBox/                      # 天空盒
│   │   ├── GradientSky/                 # 渐变天空
│   │   └── ProceduralSky/               # 程序化天空
│   └── Reflection/                      # 反射系统
│       ├── CubeMapReflection/           # Cubemap反射
│       ├── MatCap/                      # MatCap材质
│       ├── PlanarReflection/            # 平面反射
│       └── ScreenSpaceReflection/       # 屏幕空间反射
│
├── 📂 07_Scene/                         # 场景功能
│   ├── Decals/                          # 贴花系统
│   ├── Projection/                      # 投影技术
│   ├── Occlusion/                       # 遮挡处理
│   └── Transparency/                    # 透明度控制
│       ├── AlphaBlend/                  # Alpha混合
│       ├── AlphaTest/                   # Alpha测试
│       └── SoftParticle/                # 软粒子
│
├── 📂 08_Post/                          # 后处理效果
│   ├── Blur/                            # 模糊效果
│   ├── ColorGrading/                    # 调色分级
│   ├── Distortion/                      # 屏幕扭曲
│   ├── Glitch/                          # 故障效果
│   ├── RadialBlur/                      # 径向模糊
│   └── CustomEffects/                   # 自定义后处理
│
├── 📂 09_2D/                            # 2D着色器
│   ├── Sprite/                          # 精灵效果
│   │   ├── Outline/                     # 外描边/内描边
│   │   ├── InnerGlow/                   # 内发光
│   │   ├── Dissolve/                    # 溶解效果
│   │   └── ColorGrading/                # 调色/色相偏移
│   ├── UI/                              # UI特效
│   │   ├── Gradient/                    # 渐变填充
│   │   ├── Mask/                        # UI遮罩
│   │   └── Distortion/                  # UI扭曲
│   └── Effects/                         # 2D特效
│       ├── Shadow/                      # 2D阴影
│       ├── Hologram/                    # 全息效果
│       └── Glitch/                      # 故障/TikTok效果
│
├── 📂 10_Utilities/                     # 工具类
│   ├── UV/                              # UV操作
│   │   ├── Transform/                   # UV变换
│   │   ├── Scroll/                      # UV滚动
│   │   ├── Rotation/                    # UV旋转
│   │   └── Tiling/                      # UV平铺
│   ├── DataVisualization/               # 数据可视化
│   │   ├── NormalDisplay/               # 法线可视化
│   │   ├── UVDisplay/                   # UV可视化
│   │   ├── SpaceConversion/             # 空间转换显示
│   │   └── ColorChannels/               # 颜色通道显示
│   ├── Debug/                           # 调试工具
│   │   ├── Wireframe/                   # 线框模式
│   │   ├── Overdraw/                    # 过度绘制检测
│   │   └── MipMap/                      # Mipmap可视化
│   └── Helper/                          # 辅助工具
│       ├── ColorPicker/                 # 取色器
│       └── GridDisplay/                 # 网格显示
│
├── 📂 11_Advanced/                      # 高级技术
│   ├── ComputeShader/                   # 计算着色器
│   ├── RayMarching/                     # 光线步进/SDF
│   ├── ScreenSpace/                     # 屏幕空间技术
│   └── CustomPass/                      # 自定义渲染Pass
│
├── 📂 12_ShaderGraph/                   # ShaderGraph文件
│   ├── Templates/                       # ShaderGraph模板
│   ├── SubGraph/                        # 子图库
│   └── Examples/                        # ShaderGraph示例
│
├── 📂 Scripts/                          # 脚本支持
│   ├── Controllers/                     # Shader控制器脚本
│   ├── Editor/                          # 编辑器扩展
│   └── Runtime/                         # 运行时工具
│
└── 📂 Documentation/                    # 文档
    ├── README.md                        # 主文档
    ├── MIGRATION_GUIDE.md               # 迁移指南
    ├── DETAILED_MIGRATION_MAP.md        # 详细迁移映射
    ├── DIRECTORY_REFERENCE.md           # 本文档
    ├── Examples/                        # 示例场景
    └── Tutorials/                       # 教程文档
```

## 🎯 快速查找指南

### 我想找...

#### 特效相关
- **溶解效果** → `05_VFX/Dissolve/`
- **粒子着色器** → `05_VFX/Particles/`
- **扭曲效果** → `05_VFX/Distortion/`
- **发光效果** → `05_VFX/Emission/`
- **UV动画** → `05_VFX/Animation/UVAnimation/`

#### 材质相关
- **角色皮肤** → `04_Material/Character/Skin/`
- **头发材质** → `04_Material/Character/Hair/`
- **水面材质** → `04_Material/Environment/Water/`
- **玻璃材质** → `04_Material/Environment/Glass/`
- **全息效果** → `04_Material/Special/Hologram/`

#### 光照相关
- **PBR光照** → `03_Lighting/PBR/`
- **卡通渲染** → `03_Lighting/NPR/Toon/`
- **多光源** → `03_Lighting/AdvancedLighting/MultipleLights/`
- **自定义阴影** → `03_Lighting/Shadows/`

#### 表面处理
- **法线贴图** → `02_Surface/Normal/`
- **视差映射** → `02_Surface/Parallax/`
- **曲面细分** → `02_Surface/Tessellation/`

#### 2D相关
- **精灵描边** → `09_2D/Sprite/Outline/`
- **UI渐变** → `09_2D/UI/Gradient/`
- **2D阴影** → `09_2D/Effects/Shadow/`

#### 工具类
- **UV操作** → `10_Utilities/UV/`
- **调试工具** → `10_Utilities/Debug/`
- **可视化工具** → `10_Utilities/DataVisualization/`

#### 环境系统
- **雾效** → `06_Environment/Atmosphere/`
- **天空** → `06_Environment/Sky/`
- **反射** → `06_Environment/Reflection/`

#### 后处理
- **模糊** → `08_Post/Blur/`
- **调色** → `08_Post/ColorGrading/`
- **故障效果** → `08_Post/Glitch/`

## 📊 按使用场景分类

### 🎮 游戏角色制作
```
04_Material/Character/Skin/          # 皮肤材质
04_Material/Character/Hair/          # 头发材质
04_Material/Character/Cloth/         # 布料材质
03_Lighting/PBR/SkinPBR/            # 皮肤PBR光照
05_VFX/Dissolve/                    # 角色溶解效果
```

### 🌊 环境场景制作
```
04_Material/Environment/Water/       # 水面材质
04_Material/Environment/Foliage/     # 植被材质
04_Material/Environment/Terrain/     # 地形材质
06_Environment/Atmosphere/           # 大气效果
06_Environment/Sky/                  # 天空系统
```

### ✨ 特效制作
```
05_VFX/Particles/                   # 粒子效果
05_VFX/Dissolve/                    # 溶解效果
05_VFX/Emission/                    # 发光效果
05_VFX/Animation/                   # 动画效果
```

### 🎨 卡通/风格化渲染
```
03_Lighting/NPR/                    # 卡通光照
04_Material/Environment/Water/StylizedWater/  # 风格化水
```

### 📱 UI/2D游戏
```
09_2D/Sprite/                       # 精灵效果
09_2D/UI/                          # UI特效
09_2D/Effects/                     # 2D特效
```

### 🔬 学习和调试
```
01_Foundation/                      # 基础知识
10_Utilities/Debug/                # 调试工具
10_Utilities/DataVisualization/    # 数据可视化
Documentation/Tutorials/            # 教程
```

## 🏷️ 命名规范

### 文件命名
- **Shader文件**：`[序号]_[功能描述].shader`
  - 例：`05_BasicDissolve.shader`
- **ShaderGraph**：`[功能描述].shadergraph`
  - 例：`Hologram_01.shadergraph`
- **HLSL库**：`[功能描述]Library.hlsl`
  - 例：`ParticleEffectLibrary.hlsl`

### 目录命名
- 使用英文命名
- 驼峰命名法（CamelCase）
- 描述性强，一目了然

## 🔑 关键路径速记

| 快捷代码 | 完整路径 |
|---------|----------|
| `FND` | `01_Foundation/` |
| `SRF` | `02_Surface/` |
| `LGT` | `03_Lighting/` |
| `MAT` | `04_Material/` |
| `VFX` | `05_VFX/` |
| `ENV` | `06_Environment/` |
| `SCN` | `07_Scene/` |
| `PST` | `08_Post/` |
| `2D` | `09_2D/` |
| `UTL` | `10_Utilities/` |
| `ADV` | `11_Advanced/` |
| `SG` | `12_ShaderGraph/` |

## 📈 使用频率统计（预期）

根据日常使用频率排序：

1. 🔥 `05_VFX/` - 特效制作（最常用）
2. 🔥 `04_Material/` - 材质库
3. 🔥 `03_Lighting/` - 光照系统
4. 📊 `09_2D/` - 2D着色器
5. 📊 `02_Surface/` - 表面处理
6. 📊 `06_Environment/` - 环境系统
7. 📊 `10_Utilities/` - 工具类
8. 📊 `08_Post/` - 后处理
9. 📊 `12_ShaderGraph/` - ShaderGraph
10. 📊 `01_Foundation/` - 基础架构
11. 📉 `07_Scene/` - 场景功能
12. 📉 `11_Advanced/` - 高级技术

## 💡 使用建议

### 新手入门路径
1. 📖 阅读 `Documentation/README.md`
2. 👀 浏览 `12_ShaderGraph/Examples/`
3. 🎓 学习 `Documentation/Tutorials/`
4. 🔨 从 `05_VFX/` 开始实践
5. 📚 深入 `01_Foundation/` 学习原理

### 高级用户路径
1. 直接定位到需要的功能目录
2. 参考 `01_Foundation/` 中的库函数
3. 使用 `10_Utilities/Debug/` 进行调试
4. 探索 `11_Advanced/` 中的高级技术

---

**💾 建议收藏本文档以便快速查找！**

最后更新：2026年2月13日
