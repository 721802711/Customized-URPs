using UnityEngine;
using UnityEditor;
using System;
using UnityEngine.Rendering;

public class EffectShaderGUI : ShaderGUI
{
    //OnGUI接收两个参数：
    MaterialEditor                                           m_MatEditor;                          //当前材质面板

    // Main
    MaterialProperty MainTex_Sample = null;
    MaterialProperty MainTexColor = null;

    MaterialProperty Glowintensity = null; // 发光强度

    MaterialProperty Power = null;
    MaterialProperty Alpha = null;
    MaterialProperty AorR = null; 

    MaterialProperty UV_Polar_Main = null;
    MaterialProperty PolarMainTiling = null;

    MaterialProperty SoftFade = null;
    MaterialProperty USE_Softparticle = null;
    MaterialProperty UVRot = null;
    MaterialProperty MainTexAngle = null;
    MaterialProperty UVSpeed_u = null;
    MaterialProperty UVSpeed_v = null;

    MaterialProperty USE_ChangeColor = null;
    MaterialProperty ChangeColor = null;

    // 副纹理
    MaterialProperty USE_SecondaryTex_ON = null;

    MaterialProperty SecondaryTex_Sample = null;
    MaterialProperty SecondaryTex_Speed_U = null;
    MaterialProperty SecondaryTex_Speed_V = null;

    // Mask
    MaterialProperty USE_MASK_ON = null;
    MaterialProperty MaskTex_Sample = null;
    MaterialProperty MaskTexColor = null;
    MaterialProperty MaskTexAorR = null;
    MaterialProperty MaskUV_one = null;

    MaterialProperty Mask_UV_Speed_U = null;
    MaterialProperty Mask_UV_Speed_V = null;

    MaterialProperty MaskOne_UV = null;
    MaterialProperty SpeedU = null;
    MaterialProperty SpeedV = null;

    MaterialProperty MaskUvOffsetMain = null;
    MaterialProperty MaskUvOffset = null;

    MaterialProperty UVRot_Mask = null;
    MaterialProperty MaskTexAngle = null;
    MaterialProperty MaskTexRotSpeed = null;


    // 扭曲
    MaterialProperty USE_RIM_ON = null;
    MaterialProperty DistortTex_Sample = null;

    MaterialProperty DistortStrength = null;
    MaterialProperty DistortTex_Speed_U = null;
    MaterialProperty DistortTex_Speed_V = null;

    MaterialProperty Dis_UVRot = null;
    MaterialProperty DisTexRotSpeed = null;


    // 边缘光

    MaterialProperty USE_DISTORT_ON = null;
    MaterialProperty RimColor = null;
    MaterialProperty RimPower = null;
    MaterialProperty RimRevert = null;
    MaterialProperty RimAlpha = null;

    // 溶解
    MaterialProperty USE_DISSOLVE = null;
    MaterialProperty DissolveTex_Sample = null;

    MaterialProperty DissolveAlpha = null;
    MaterialProperty DissolveDistort = null;
    MaterialProperty DissolveStrength = null;
    MaterialProperty DissolveColor = null;
    MaterialProperty DissolveWidth = null;
    MaterialProperty DissolveSmooth = null;


    // Shader属性

    MaterialProperty cullParam = null;
    MaterialProperty SrcParam = null;
    MaterialProperty DstParam = null;
    MaterialProperty ZtestParam = null;

    static bool _Base_Foldout = true; 

    static bool _Secondary_Foldout = true;
    static bool _Mask_Foldout = true;
    static bool _Dist_Foldout = true;
    static bool _Diss_Foldout = true;
    static bool _Rim_Foldout = true;
    static bool _Pro_Foldout = true;

    // ====================================================================================================================================
    // 绑定属性
    public void FindProperties(MaterialProperty[] props)
    {        
        // 基础属性
        MainTex_Sample = FindProperty("_MainTex", props, true);
        MainTexColor = FindProperty("_Color", props, true);
        Glowintensity = FindProperty("_Glowintensity", props, true); // 发光强度
        Power = FindProperty("_Power", props, true);
        Alpha = FindProperty("_Alpha", props, true);
        AorR = FindProperty("_AorR", props, true);
        UV_Polar_Main = FindProperty("_UV_Polar_Main", props, true);
        PolarMainTiling = FindProperty("_PolarMainTiling", props, true);

        SoftFade = FindProperty("_SoftFade", props, true);
        USE_Softparticle = FindProperty("_Toggle_USE_SOFTPARTICLE_ON", props, true);

        UVRot = FindProperty("_UVRot", props, true);
        MainTexAngle = FindProperty("_MainTexAngle", props, true);

        UVSpeed_u = FindProperty("_UV_Speed_U_Main", props, true);
        UVSpeed_v = FindProperty("_UV_Speed_V_Main", props, true);

        ChangeColor = FindProperty("_ChangeColor", props, true);
        USE_ChangeColor = FindProperty("_Toggle_USE_CHANGECOLOR_ON", props, true);

        // 副纹理
        USE_SecondaryTex_ON = FindProperty("_USE_SECONDARYTEX", props, true);
        SecondaryTex_Sample = FindProperty("_SecondaryTex", props, true);
        SecondaryTex_Speed_U = FindProperty("_SecondaryTex_Speed_U", props, true);
        SecondaryTex_Speed_V = FindProperty("_SecondaryTex_Speed_V", props, true);


        // MASK
        USE_MASK_ON = FindProperty("_USE_MASK", props, true);
        MaskTex_Sample = FindProperty("_MaskTex", props, true);
        MaskTexColor = FindProperty("_MaskTexColor", props, true);
        MaskTexAorR = FindProperty("_MaskTexAorR", props, true);
        MaskUV_one = FindProperty("_MaskUV_one", props, true);

        Mask_UV_Speed_U = FindProperty("_UV_Speed_U_Mask", props, true);
        Mask_UV_Speed_V = FindProperty("_UV_Speed_V_Mask", props, true);

        MaskOne_UV = FindProperty("_MaskOne_UV", props, true);
        SpeedU = FindProperty("_speedU", props, true);
        SpeedV = FindProperty("_speedV", props, true);

        MaskUvOffsetMain = FindProperty("_MaskUvOffsetMain", props, true);
        MaskUvOffset = FindProperty("_MaskUvOffset", props, true);

        UVRot_Mask = FindProperty("_UVRot_Mask", props, true);
        MaskTexAngle = FindProperty("_MaskTexAngle", props, true);
        MaskTexRotSpeed = FindProperty("_MaskTexRotSpeed", props, true);

        // Dis
        USE_DISTORT_ON = FindProperty("_Toggle_USE_DISTORT_ON", props, true);
        DistortTex_Sample = FindProperty("_DistortTex", props, true);

        DistortStrength = FindProperty("_DistortStrength", props, true);
        DistortTex_Speed_U = FindProperty("_DistortTex_Speed_U", props, true);
        DistortTex_Speed_V = FindProperty("_DistortTex_Speed_V", props, true);
        Dis_UVRot = FindProperty("_UVRot_DistortTex", props, true);
        DisTexRotSpeed = FindProperty("_DistortTexRotSpeed", props, true);


        // 边缘光

        USE_RIM_ON = FindProperty("_Toggle_USE_RIM_ON", props, true);
        RimColor = FindProperty("_RimColor", props, true);
        RimPower = FindProperty("_RimPower", props, true);
        RimRevert = FindProperty("_RimRevert", props, true);
        RimAlpha = FindProperty("_RimAlpha", props, true);


        // Diss
        USE_DISSOLVE = FindProperty("_Toggle_USE_DISSOLVE_ON", props, true);
        DissolveTex_Sample = FindProperty("_DissolveTex", props, true);

        DissolveAlpha = FindProperty("_DissolveAlpha", props, true);
        DissolveDistort = FindProperty("_DissolveDistort", props, true);

        DissolveStrength = FindProperty("_DissolveStrength", props, true);
        DissolveColor = FindProperty("_DissolveColor", props, true);
        DissolveWidth = FindProperty("_DissolveWidth", props, true);
        DissolveSmooth = FindProperty("_DissolveSmooth", props, true);


        // 属性 
        cullParam = FindProperty("_cull", props);
        SrcParam = FindProperty("_SrcBlend", props);
        DstParam = FindProperty("_DstBlend", props);
        ZtestParam = FindProperty("_zTest", props);
    }
    private static class Styles
    {
        public static GUIContent content = new GUIContent("主贴图");   // tips 是说明文字，鼠标悬停属性名称时显示

        public static GUIContent maintex = new GUIContent("副贴图");
        public static GUIContent masktex = new GUIContent("Mask贴图");
        public static GUIContent disttex = new GUIContent("扭曲贴图");
        public static GUIContent disstex = new GUIContent("溶解贴图");

    }
    // 按钮
    public GUILayoutOption[] shortButtonStyle = new GUILayoutOption[] { GUILayout.Width(100) , GUILayout.Height(30) };
    // 折叠栏
    static bool Foldout(bool display, string title)
    {
        var style = new GUIStyle("ShurikenModuleTitle");
        style.font = new GUIStyle(EditorStyles.boldLabel).font;
        style.border = new RectOffset(15, 7, 4, 4);
        style.fixedHeight = 22;
        style.contentOffset = new Vector2(20f, -2f);

        var rect = GUILayoutUtility.GetRect(16f, 22f, style);
        GUI.Box(rect, title, style);

        var e = Event.current;

        var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
        if (e.type == EventType.Repaint)
        {
            EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
        }

        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
        {
            display = !display;
            e.Use();
        }

        return display;
    }



    // 绘制UI
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        FindProperties(props);
        m_MatEditor = materialEditor;
        Material material = materialEditor.target as Material;                       // 材质

        // ===================================================================================================

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Base_Foldout = Foldout(_Base_Foldout, "主贴图设置");
        if (_Base_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            MainTex(material);
            EditorGUI.indentLevel--;
            EditorGUILayout.Space(10);
        }

        EditorGUILayout.EndVertical();

        // 增加副纹理区域
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Secondary_Foldout = Foldout(_Secondary_Foldout, "副贴图设置");

        if (_Secondary_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            SecondaryTex(material);
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndVertical();

        // ===================================================================================================
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Mask_Foldout = Foldout(_Mask_Foldout, "Mask设置");
        if (_Mask_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            MaskTex(material);
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndVertical();


        // ===================================================================================================
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Dist_Foldout = Foldout(_Dist_Foldout, "扭曲设置");
        if (_Dist_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            DistortTex(material);
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndVertical();


        // ===================================================================================================
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Rim_Foldout = Foldout(_Rim_Foldout, "边缘光设置");

        if (_Rim_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            Rim(material);
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndVertical();

        // ===================================================================================================

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Diss_Foldout = Foldout(_Diss_Foldout, "溶解设置");
        if (_Diss_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            DissolveTex(material);
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndVertical();



        // ===================================================================================================

        // Shader属性
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Pro_Foldout = Foldout(_Pro_Foldout, "Shader设置");
        if (_Pro_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.Space(10);
            ShaderProGUI(material);
            EditorGUI.indentLevel--;
            EditorGUILayout.Space(10);

        }
        EditorGUILayout.EndVertical();
        Draw_BlendTagUI(material);

    }

    // ====================================================================================================================================
    // 板块方法
    void MainTex(Material mat) 
    {

        if (MainTex_Sample.textureValue != null)
        {
            //m_MatEditor.TextureProperty(MainTex_Sample, "主贴图");

            m_MatEditor.TexturePropertySingleLine(Styles.content, MainTex_Sample, MainTexColor);               //重载方法
            // 贴图的平铺和偏移
            EditorGUI.indentLevel++;

            var _TexAorR_ON = EditorGUILayout.Toggle("使用R当Alpha通道", AorR.floatValue == 1);   // 声明开关类型
            if (EditorGUI.EndChangeCheck()) AorR.floatValue = _TexAorR_ON ? 1 : 0;

            m_MatEditor.RangeProperty(Alpha, "Alpha");

            m_MatEditor.TextureScaleOffsetProperty(MainTex_Sample);


            EditorGUI.indentLevel--;

            // 全局
            GUILayout.Space(10);
            m_MatEditor.RangeProperty(Power, "对比度");
            m_MatEditor.RangeProperty(Glowintensity, "发光强度"); // 发光强度

            GUILayout.Space(10);
            var _UV_Polar_ON = EditorGUILayout.Toggle("uv 极坐标(中心方向)", UV_Polar_Main.floatValue == 1);   // 声明开关类型
            if (EditorGUI.EndChangeCheck()) UV_Polar_Main.floatValue = _UV_Polar_ON ? 1 : 0;
            if (UV_Polar_Main.floatValue == 1)
            {
                m_MatEditor.VectorProperty(PolarMainTiling, "极坐标缩放(Tiling: x, y; Offset: z, w)");
            }

            // 软粒子
            var _SOFT_ON = EditorGUILayout.Toggle("软粒子", USE_Softparticle.floatValue == 1);   // 声明开关类型
            if (EditorGUI.EndChangeCheck()) USE_Softparticle.floatValue = _SOFT_ON ? 1 : 0;
            if (USE_Softparticle.floatValue == 1)
            {
                mat.EnableKeyword("_USE_SOFTPARTICLE");             // 打开变体
                m_MatEditor.RangeProperty(SoftFade, "柔和度");
            }
            else
            {
                mat.DisableKeyword("_USE_SOFTPARTICLE");             // 关闭变体
            }


            // 贴图旋转 UV速度

            var _UVRot_ON = EditorGUILayout.Toggle("贴图旋转 UV方向移动", UVRot.floatValue == 1);   // 声明开关类型
            if (EditorGUI.EndChangeCheck()) UVRot.floatValue = _UVRot_ON ? 1 : 0;

            if (UVRot.floatValue == 1)
            {
                m_MatEditor.RangeProperty(MainTexAngle, "纹理旋转");
                m_MatEditor.FloatProperty(UVSpeed_u, "纹理U方向速度");
                m_MatEditor.FloatProperty(UVSpeed_v, "纹理V方向速度");
            }

            // 软粒子
            var _ChangeCol_ON = EditorGUILayout.Toggle("整体换色", USE_ChangeColor.floatValue == 1);   // 声明开关类型
            if (EditorGUI.EndChangeCheck()) USE_ChangeColor.floatValue = _ChangeCol_ON ? 1 : 0;
            if (USE_ChangeColor.floatValue == 1)
            {
                mat.EnableKeyword("_USE_CHANGECOLOR");             // 打开变体
                m_MatEditor.ColorProperty(ChangeColor, "换色");
            }
            else
            {
                mat.DisableKeyword("_USE_CHANGECOLOR");             // 关闭变体
            }

            EditorGUI.indentLevel--; 


        }
        else
            m_MatEditor.TexturePropertySingleLine(Styles.content, MainTex_Sample);               //重载方法



    }

    // 副纹理
    void SecondaryTex(Material mat)
    {
        EditorGUI.indentLevel++;
        var _USE_SECONDARY_ON = EditorGUILayout.Toggle("副纹理", USE_SecondaryTex_ON.floatValue == 1);   // 声明切换
        if (EditorGUI.EndChangeCheck()) USE_SecondaryTex_ON.floatValue = _USE_SECONDARY_ON ? 1 : 0;

        EditorGUI.indentLevel--;

        if (USE_SecondaryTex_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_SECONDARYTEX");             // 打开变体
            m_MatEditor.TexturePropertySingleLine(Styles.maintex, SecondaryTex_Sample);
            m_MatEditor.TextureScaleOffsetProperty(SecondaryTex_Sample);
            m_MatEditor.FloatProperty(SecondaryTex_Speed_U, "副纹理U方向速度");
            m_MatEditor.FloatProperty(SecondaryTex_Speed_V, "副纹理V方向速度");
            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_SECONDARYTEX");             // 关闭变体
        }
        EditorGUILayout.Space(10);
    }

    // 遮罩
    void MaskTex(Material mat)
    {

        EditorGUI.indentLevel++;
        var _USE_MASK_ON = EditorGUILayout.Toggle("遮罩Mask", USE_MASK_ON.floatValue == 1);   // 声明切换
        if (EditorGUI.EndChangeCheck()) USE_MASK_ON.floatValue = _USE_MASK_ON ? 1 : 0;



        EditorGUI.indentLevel--;

        if (USE_MASK_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_MASK");             // 打开变体


            m_MatEditor.TexturePropertySingleLine(Styles.masktex, MaskTex_Sample);
            m_MatEditor.ColorProperty(MaskTexColor, "遮罩系数");
            m_MatEditor.TextureScaleOffsetProperty(MaskTex_Sample);
            EditorGUILayout.Space(10);


            var _MASK_AorR_ON = EditorGUILayout.Toggle("使用R当Alpha通道", MaskTexAorR.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) MaskTexAorR.floatValue = _MASK_AorR_ON ? 1 : 0;

            var _MASK_UVone_ON = EditorGUILayout.Toggle("UV循环或者一次性(默认循环)", MaskUV_one.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) MaskUV_one.floatValue = _MASK_UVone_ON ? 1 : 0;

            if (MaskUV_one.floatValue == 1)
            {
                var _MASK_one_ON = EditorGUILayout.Toggle("随粒子Custom_Y值UV", MaskOne_UV.floatValue == 1);   // 声明切换
                if (EditorGUI.EndChangeCheck()) MaskOne_UV.floatValue = _MASK_one_ON ? 1 : 0;

                m_MatEditor.RangeProperty(SpeedU, "纹理U方向");
                m_MatEditor.RangeProperty(SpeedV, "纹理V方向");

            }
            else
            {
                m_MatEditor.FloatProperty(Mask_UV_Speed_U, "纹理U方向速度");
                m_MatEditor.FloatProperty(Mask_UV_Speed_V, "纹理V方向速度");
            }

            var _MASK_Offset_ON = EditorGUILayout.Toggle("遮罩UV偏移", MaskUvOffsetMain.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) MaskUvOffsetMain.floatValue = _MASK_Offset_ON ? 1 : 0;

            if (MaskUvOffsetMain.floatValue == 1)
            {
                m_MatEditor.FloatProperty(MaskUvOffset, "遮罩UV偏移系数");
            }

            var _MASK_Rot_ON = EditorGUILayout.Toggle("遮罩纹理UV 旋转", UVRot_Mask.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) UVRot_Mask.floatValue = _MASK_Rot_ON ? 1 : 0;

            if (UVRot_Mask.floatValue == 1)
            {
                m_MatEditor.FloatProperty(MaskTexAngle, "遮罩纹理旋转");
                m_MatEditor.FloatProperty(MaskTexRotSpeed, "遮罩旋转速度");
            }


            EditorGUI.indentLevel--;


        }
        else
        {
            mat.DisableKeyword("_USE_MASK");             // 关闭变体
        }
        EditorGUILayout.Space(10);
    }

    // 扭曲
    void DistortTex(Material mat)
    {

        EditorGUI.indentLevel++;
        var _USE_DISTORT_ON = EditorGUILayout.Toggle("扭曲", USE_DISTORT_ON.floatValue == 1);   // 声明切换
        if (EditorGUI.EndChangeCheck()) USE_DISTORT_ON.floatValue = _USE_DISTORT_ON ? 1 : 0;

        EditorGUI.indentLevel--;


        if (USE_DISTORT_ON.floatValue == 1)
        {

            mat.EnableKeyword("_USE_DISTORT");             // 打开变体
            EditorGUI.indentLevel++;

            m_MatEditor.TexturePropertySingleLine(Styles.disttex, DistortTex_Sample);
            m_MatEditor.TextureScaleOffsetProperty(DistortTex_Sample);
            EditorGUILayout.Space(10);

            m_MatEditor.RangeProperty(DistortStrength, "扭曲强度");
            m_MatEditor.FloatProperty(DistortTex_Speed_U, "U 方向扭曲速度");
            m_MatEditor.FloatProperty(DistortTex_Speed_V, "V 方向扭曲速度");

            EditorGUILayout.Space(10);

            var _TEXROT_ON = EditorGUILayout.Toggle("扭曲纹理uv 旋转", Dis_UVRot.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) Dis_UVRot.floatValue = _TEXROT_ON ? 1 : 0;

            if (Dis_UVRot.floatValue == 1)
            {
                m_MatEditor.FloatProperty(DisTexRotSpeed, "扭曲旋转速度");
            }
            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_DISTORT");             // 关闭变体
        }
        EditorGUILayout.Space(10);
    }

    // 边缘光效果
    void Rim(Material mat)
    {
        EditorGUI.indentLevel++;
        var _RIM_ON = EditorGUILayout.Toggle("边缘光", USE_RIM_ON.floatValue == 1);   // 声明切换
        if (EditorGUI.EndChangeCheck()) USE_RIM_ON.floatValue = _RIM_ON ? 1 : 0;



        EditorGUI.indentLevel--;

        if (USE_RIM_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_RIM");             // 打开变体
            m_MatEditor.ColorProperty(RimColor, "边缘光颜色");
            m_MatEditor.RangeProperty(RimPower, "边缘光强度");
            m_MatEditor.FloatProperty(RimRevert, "边缘光反向");
            m_MatEditor.FloatProperty(RimAlpha, "边缘光Alpha反向");
            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_RIM");             // 关闭变体
        }
        EditorGUILayout.Space(10);
    }

    // 溶解
    void DissolveTex(Material mat)
    {
        EditorGUI.indentLevel++;

        var _USE_DISSOLVE_NO = EditorGUILayout.Toggle("溶解", USE_DISSOLVE.floatValue == 1);
        if (EditorGUI.EndChangeCheck()) USE_DISSOLVE.floatValue = _USE_DISSOLVE_NO ? 1 : 0;

        EditorGUI.indentLevel--;

        if (USE_DISSOLVE.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_DISSOLVE");             // 打开变体

            m_MatEditor.TexturePropertySingleLine(Styles.disstex, DissolveTex_Sample);
            m_MatEditor.TextureScaleOffsetProperty(DissolveTex_Sample);
            EditorGUILayout.Space(10);

            var _DIS_CUS_ON = EditorGUILayout.Toggle("随粒子Custom值溶解", DissolveAlpha.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) DissolveAlpha.floatValue = _DIS_CUS_ON ? 1 : 0;

            var _DIS_DIT_ON = EditorGUILayout.Toggle("溶解开启扭曲", DissolveDistort.floatValue == 1);   // 声明切换
            if (EditorGUI.EndChangeCheck()) DissolveDistort.floatValue = _DIS_DIT_ON ? 1 : 0;

            m_MatEditor.RangeProperty(DissolveStrength, "溶解度");
            m_MatEditor.ColorProperty(DissolveColor, "溶解边缘颜色");
            m_MatEditor.RangeProperty(DissolveWidth, "溶解边缘宽度");
            m_MatEditor.RangeProperty(DissolveSmooth, "边缘硬度");
            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_DISSOLVE");             // 关闭变体
        }
        EditorGUILayout.Space(10);
    }

    // ====================================================================================================================================

    // Shader的一些设置属性
    void ShaderProGUI(Material mat)
    {
        EditorGUILayout.BeginHorizontal();

        EditorGUILayout.PrefixLabel("ZwriteMode深度读写");
        GUILayout.Space(20);
        if (mat.GetFloat("_zWrite") == 0)
        {
            if (GUILayout.Button("开 启", shortButtonStyle))
            {
                mat.SetFloat("_zWrite", 1);
            }
        }
        else
        {
            if (GUILayout.Button("关 闭", shortButtonStyle))
            {
                mat.SetFloat("_zWrite", 0);
            }
        }

        EditorGUILayout.EndHorizontal();

        // 混合属性
        EditorGUI.BeginChangeCheck();
        {
            MaterialProperty[] props = { SrcParam, DstParam, cullParam , ZtestParam };
            base.OnGUI(m_MatEditor, props);
        }
        
    }

    
    // ====================================================================================================================================
    // 处理
    private static GUIContent[] _blendTagUIGUIContents;
    protected static GUIContent[] BlendTagUIGUIContents
    {
        get
        {
            //index label                 Value
            //0     普通                  One Zero
            //1     Alpha混合             SrcAlpha OneMinusSrcAlpha
            //2     叠加                  SrcAlpha One
            //3     叠加(忽略Alpha)       One One
            if (_blendTagUIGUIContents == null)
            {
                _blendTagUIGUIContents = new GUIContent[4];
                _blendTagUIGUIContents[0] = new GUIContent("普通");
                _blendTagUIGUIContents[1] = new GUIContent("Alpha混合");
                _blendTagUIGUIContents[2] = new GUIContent("叠加");
                _blendTagUIGUIContents[3] = new GUIContent("叠加(忽略Alpha)");
            }

            return _blendTagUIGUIContents;
        }
    }             // 设置按钮文字
    private void Draw_BlendTagUI(Material material)                         // 设置 混合模式
    {
        GUILayout.BeginVertical("box");
        GUILayout.Space(5);

        GUILayout.Label("混合模式:");
        GUILayout.Space(5);

        
        //获取index
        int index = GetBlendValuesIndex(material);
        int xCount = Screen.width >= 480 ? 4 : (int)Screen.width / 120;
        int hNum = Mathf.CeilToInt((float)BlendTagUIGUIContents.Length / xCount);
        int SGHeight = hNum * 30;
        index = GUILayout.SelectionGrid(index, BlendTagUIGUIContents, xCount, GUILayout.Height(SGHeight));

        GUILayout.Space(5);
        GUILayout.EndVertical();
        
        switch (index)
        {
            case 0:
                //0  普通  One Zero
                material.SetInt("_SrcBlend", (int)BlendMode.One);
                material.SetInt("_DstBlend", (int)BlendMode.Zero);
                break;
            case 1:
                //1  Alpha混合  SrcAlpha OneMinusSrcAlpha
                material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
                break;
            case 2:
                //2  叠加  SrcAlpha One
                material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)BlendMode.One);
                break;
            case 3:
                //3  叠加(忽略Alpha)  One One
                material.SetInt("_SrcBlend", (int)BlendMode.One);
                material.SetInt("_DstBlend", (int)BlendMode.One);
                break;
            default:
                break;
        }
        
    }

    private int GetBlendValuesIndex(Material material)                 // 输出不同的模式的数字
    {
        BlendMode SrcBlend = (BlendMode)material.GetInt("_SrcBlend");
        BlendMode DstBlend = (BlendMode)material.GetInt("_DstBlend");

        if (SrcBlend == BlendMode.One && DstBlend == BlendMode.Zero)
        {
            //0  普通  One Zero
            return 0;
        }

        if (SrcBlend == BlendMode.SrcAlpha && DstBlend == BlendMode.OneMinusSrcAlpha)
        {
            //1  Alpha混合  SrcAlpha OneMinusSrcAlpha
            return 1;
        }

        if (SrcBlend == BlendMode.SrcAlpha && DstBlend == BlendMode.One)
        {
            //2  叠加  SrcAlpha One
            return 2;
        }

        if (SrcBlend == BlendMode.One && DstBlend == BlendMode.One)
        {
            //3  叠加(忽略Alpha)  One One
            return 3;
        }

        return -1;
    }
    
}

