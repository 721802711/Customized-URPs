# 详细迁移映射表

本文档提供具体Shader文件的迁移建议。

## 📋 文件级迁移清单

### 11_Effect（特效）→ 05_VFX

#### 溶解效果 (Dissolve)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_04_Dissolve_Basic.shader` | `05_VFX/Dissolve/BasicDissolve/` | 基础溶解 |
| `11_05_Dissolve_EdgeColor.shader` | `05_VFX/Dissolve/EdgeColor/` | 边缘颜色溶解 |
| `11_06_Dissolve_TwoEdgeColor.shader` | `05_VFX/Dissolve/EdgeColor/` | 双边缘颜色 |
| `11_07_Dissolve_BlendOriginColor.shader` | `05_VFX/Dissolve/BasicDissolve/` | 混合原始颜色 |
| `11_08_Dissolve_Ramp.shader` | `05_VFX/Dissolve/AdvancedDissolve/` | Ramp溶解 |
| `11_09_Dissolve_FromPint.shader` | `05_VFX/Dissolve/PointDissolve/` | 点溶解 |
| `11_10_Dissolve_FromDirectionX.shader` | `05_VFX/Dissolve/DirectionalDissolve/` | X方向溶解 |
| `11_10_Dissolve_UP.shader` | `05_VFX/Dissolve/DirectionalDissolve/` | 向上溶解 |
| `11_11_Dissolve_DirectionAsh.shader` | `05_VFX/Dissolve/AdvancedDissolve/` | 灰烬溶解 |
| `11_12_Dissolve_ToPoint.shader` | `05_VFX/Dissolve/PointDissolve/` | 向点溶解 |

#### 扭曲效果 (Distortion)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_13_Air_Distortion.shader` | `05_VFX/Distortion/AirDistortion/` | 空气扭曲 |
| `Distort.shadergraph` | `05_VFX/Distortion/HeatWave/` | 扭曲效果 |
| `DistortWrold.shadergraph` | `05_VFX/Distortion/WorldDistortion/` | 世界空间扭曲 |

#### 发光效果 (Emission)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `Glow.shadergraph` | `05_VFX/Emission/Glow/` | 辉光 |
| `EdgeLight.shadergraph` | `05_VFX/Emission/EdgeLight/` | 边缘光 |

#### 遮罩效果 (Mask)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_02_UVMask.shader` | `05_VFX/Mask/UVMask/` | UV遮罩 |
| `11_21_DisMaskEffect.shader` | `05_VFX/Mask/DirectionalMask/` | 方向遮罩效果 |

#### 粒子效果 (Particles)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_15_Particle.shader` | `05_VFX/Particles/StandardParticle/` | 标准粒子 |
| `11_22_Particle_UP.shader` | `05_VFX/Particles/CustomParticle/` | URP粒子 |

#### 动画效果 (Animation)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_14_UVAnimation.shader` | `05_VFX/Animation/UVAnimation/` | UV动画 |
| `11_16_Noise.shader` | `05_VFX/Animation/Noise/` | 噪波动画 |

#### 特殊效果 (Special)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `11_01_Effect.shader` | `05_VFX/Particles/StandardParticle/` | 基础特效 |
| `11_03_Custom.shader` | `05_VFX/Particles/CustomParticle/` | 自定义特效 |
| `11_17_CommonEffect.shader` | `05_VFX/Particles/StandardParticle/` | 通用特效 |
| `11_18_EffectCharacter.shader` | `04_Material/Character/` | 角色特效 |
| `11_19_Effect_Ramp_Luminance.shader` | `05_VFX/Emission/Glow/` | Ramp亮度 |
| `11_19_Effect_Ramp_UV.shader` | `05_VFX/Animation/UVAnimation/` | Ramp UV |
| `11_20_Effect_Ramp_Switch.shader` | `05_VFX/Emission/Glow/` | Ramp开关 |
| `Hologram_01.shadergraph` | `04_Material/Special/Hologram/` | 全息投影 v1 |
| `Hologram_02.shadergraph` | `04_Material/Special/Hologram/` | 全息投影 v2 |
| `Hologram_03.shadergraph` | `04_Material/Special/Hologram/` | 全息投影 v3 |
| `Dis.shadergraph` | `05_VFX/Dissolve/BasicDissolve/` | ShaderGraph溶解 |

#### HLSL库文件
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `HLSLEffectParticleLibrary.hlsl` | `01_Foundation/Base/` | 特效粒子库 |
| `HLSLEffectParticleLibraryUP.hlsl` | `01_Foundation/Base/` | URP特效粒子库 |

---

### 17_Material（材质）→ 04_Material

#### 特殊材质
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `17_BaseGlitter_01.shader` | `04_Material/Special/` | 基础闪光 |
| `17_Glitter.shader` | `04_Material/Special/` | 闪光材质 |
| `17_Sparkle02.shader` | `04_Material/Special/` | 火花效果 |

#### 彩虹/彩色材质
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `17_Rainbow_03.shader` | `04_Material/Special/` | 彩虹效果 v3 |
| `17_Rainbow_04.shader` | `04_Material/Special/` | 彩虹效果 v4 |
| `17_Rainbow_05.shader` | `04_Material/Special/` | 彩虹效果 v5 |
| `Rainbow.shadergraph` | `04_Material/Special/` | ShaderGraph彩虹 |

#### 环境材质
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `17_SnowEffect.shader` | `04_Material/Environment/` | 雪效果 |

#### ShaderGraph文件
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `P.shadergraph` | `12_ShaderGraph/Examples/` | 示例图P |

#### HLSL库文件
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `BaseGlitterPass.hlsl` | `01_Foundation/Base/` | 基础闪光Pass |

---

### 05_2D（2D着色器）→ 09_2D

#### 精灵效果 (Sprite)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `05_2DOutine.shader` | `09_2D/Sprite/Outline/` | 外描边 |
| `05_2DInnerOutLine.shader` | `09_2D/Sprite/Outline/` | 内描边 |
| `05_2DGlow.shader` | `09_2D/Sprite/InnerGlow/` | 内发光 |
| `05_2DFade.shader` | `09_2D/Sprite/Dissolve/` | 淡出效果 |
| `05_2DColorSwap.shader` | `09_2D/Sprite/ColorGrading/` | 颜色交换 |
| `05_2DHueShift.shader` | `09_2D/Sprite/ColorGrading/` | 色相偏移 |

#### UI特效 (UI)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `05_2DGradient.shader` | `09_2D/UI/Gradient/` | 渐变 |
| `05_UVMoving.shader` | `09_2D/UI/Distortion/` | UV移动 |

#### 2D特效 (Effects)
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `05_2DShadow.shader` | `09_2D/Effects/Shadow/` | 2D阴影 |
| `05_2DHologram.shader` | `09_2D/Effects/Hologram/` | 2D全息 |
| `05_2DGlith.shader` | `09_2D/Effects/Glitch/` | 2D故障 |
| `05_2DTikTok.shader` | `09_2D/Effects/Glitch/` | TikTok故障 |
| `05_2DGhost.shader` | `09_2D/Effects/` | 幽灵效果 |
| `05_2DShine.shader` | `09_2D/Effects/` | 闪光效果 |

#### 其他效果
| 原文件 | 建议迁移位置 | 说明 |
|--------|-------------|------|
| `05_2DBlur.shader` | `08_Post/Blur/` 或 `09_2D/Effects/` | 2D模糊 |
| `05_2DPixel.shader` | `09_2D/Effects/` | 像素化 |

---

### 其他目录迁移建议

#### 00_Base → 01_Foundation
```
00_Base/
├── Shader/          → 01_Foundation/Base/
├── Material/        → 保留作为示例材质
├── Textures/        → 保留作为示例纹理
├── Models/          → 保留作为测试模型
└── Scene/           → Documentation/Examples/
```

#### 01_LightingModel → 03_Lighting
```
01_LightingModel/Shader/  → 03_Lighting/Standard/ 或 03_Lighting/PBR/
```

#### 02_Bump → 02_Surface/Normal
```
02_Bump/Shader/  → 02_Surface/Normal/BumpMapping/ 或 NormalMapping/
```

#### 03_Parallax → 02_Surface/Parallax
```
03_Parallax/Shader/  → 02_Surface/Parallax/ (根据具体类型选择子目录)
```

#### 04_MultipleLightSources → 03_Lighting/AdvancedLighting
```
04_MultipleLightSources/Shader/  → 03_Lighting/AdvancedLighting/MultipleLights/
```

#### 06_MathFun → 01_Foundation/MathUtilities
```
06_MathFun/  → 01_Foundation/MathUtilities/
```

#### 07_VertexAnimation → 05_VFX/Animation
```
07_VertexAnimation/Shader/  → 05_VFX/Animation/VertexAnimation/
```

#### 08_UV → 10_Utilities/UV
```
08_UV/Shader/  → 10_Utilities/UV/ (根据功能选择Transform/Scroll/Rotation/Tiling)
```

#### 09_AlternativeLighting → 03_Lighting/NPR
```
09_AlternativeLighting/Shader/  → 03_Lighting/NPR/ (Toon/Cel/Ramp根据类型)
```

#### 10_Environment → 06_Environment
```
10_Environment/Shader/  → 06_Environment/ (根据类型选择Atmosphere/Sky/Reflection)
```

#### 12_Tessellation → 02_Surface/Tessellation
```
12_Tessellation/Shader/  → 02_Surface/Tessellation/ (Flat/Phong/PN/Displacement)
```

#### 13_Scene → 07_Scene
```
13_Scene/Shader/  → 07_Scene/ (Decals/Projection/Occlusion/Transparency)
```

#### 14_Data → 10_Utilities/DataVisualization
```
14_Data/Shader/  → 10_Utilities/DataVisualization/ 或 Debug/
```

#### 15_Post → 08_Post
```
15_Post/Shader/  → 08_Post/ (Blur/ColorGrading/Distortion/Glitch/etc)
```

#### 16_Dynamic → 05_VFX/Animation
```
16_Dynamic/Shader/  → 05_VFX/Animation/ (根据具体动画类型)
```

#### 999_Shader → 12_ShaderGraph/Examples
```
999_Shader/  → 12_ShaderGraph/Examples/ 或保留用于临时测试
```

---

## 🔧 迁移工具脚本建议

可以创建Unity Editor脚本来辅助迁移：

```csharp
// 示例：自动迁移脚本框架
public class ShaderMigrationTool : EditorWindow
{
    [MenuItem("Tools/Shader Migration")]
    static void ShowWindow()
    {
        GetWindow<ShaderMigrationTool>("Shader Migration");
    }
    
    void OnGUI()
    {
        if (GUILayout.Button("Migrate 11_Effect to 05_VFX"))
        {
            MigrateEffectShaders();
        }
        
        if (GUILayout.Button("Migrate 05_2D to 09_2D"))
        {
            Migrate2DShaders();
        }
        
        // 添加更多迁移按钮...
    }
    
    void MigrateEffectShaders()
    {
        // 实现迁移逻辑
        // 1. 查找所有shader文件
        // 2. 根据映射表移动文件
        // 3. 保留GUID避免引用丢失
        // 4. 生成迁移报告
    }
}
```

---

## ⚠️ 迁移注意事项

### 关键提醒
1. **备份优先**：迁移前务必备份整个项目或使用版本控制
2. **使用Unity移动**：在Unity Editor中移动文件以保持引用
3. **测试验证**：迁移后测试所有使用了这些Shader的场景和Prefab
4. **逐步迁移**：建议分批次迁移，每次完成一个大类
5. **更新文档**：记录实际迁移情况，与本文档对比

### 推荐迁移顺序
1. ✅ 创建新目录结构（已完成）
2. 📝 迁移HLSL库文件到 `01_Foundation/Base/`
3. 📝 迁移 `11_Effect/` 到 `05_VFX/`
4. 📝 迁移 `05_2D/` 到 `09_2D/`
5. 📝 迁移 `17_Material/` 到 `04_Material/`
6. 📝 迁移其他目录
7. 📝 清理和优化
8. 📝 更新所有引用和文档

### 迁移后检查清单
- [ ] 所有Shader文件已迁移
- [ ] Material引用正常
- [ ] 测试场景运行正常
- [ ] Prefab资源无丢失
- [ ] 文档已更新
- [ ] 旧目录已归档或删除

---

**最后更新**：2026年2月13日  
**建议定期更新本文档**：随着迁移进展更新完成状态
