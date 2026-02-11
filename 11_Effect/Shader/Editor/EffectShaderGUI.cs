using UnityEngine;
using UnityEditor;
using System;
using UnityEngine.Rendering;


/*
 Custom 参数的使用说明
 x：控制溶解
 y: 控制Mask的U方向偏移
 z: 控制Mask的V方向偏移
 w：控制整体亮度

*/

// ====================================================================================================================================

public class EffectShaderGUI : ShaderGUI
{
    //OnGUI接收两个参数：
    MaterialEditor m_MatEditor;                          //当前材质面板

    // Main
    MaterialProperty MainTex_Sample = null;
    MaterialProperty MainTexChannel = null;    // 设置主贴图不同通道枚举
    MaterialProperty MainTexColor = null;
    MaterialProperty Glowintensity = null; // 发光强度
    MaterialProperty UseCustomColor = null; // 使用Custom控制强度变化




    MaterialProperty Power = null;
    MaterialProperty Alpha = null;
    MaterialProperty AorR = null;

    MaterialProperty UV_Polar_Main = null;
    MaterialProperty PolarMainTiling = null;

    MaterialProperty SoftFade = null;
    MaterialProperty USE_Softparticle = null;
    MaterialProperty UVRot = null;

    MaterialProperty UseCustom2MainUV = null; // 新增变量，控制是否使用 Custom2 作为主贴图 UV 偏移
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

    MaterialProperty MaskTex_Channel = null;   // 设置Mask贴图不同通道枚举
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

    // 遮罩扭曲
    MaterialProperty MaskDistort = null;
    MaterialProperty MaskDistortStrength = null;


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

    MaterialProperty Dissolve_Speed_U = null;
    MaterialProperty Dissolve_Speed_V = null;

    // Shader属性

    MaterialProperty cullParam = null;
    MaterialProperty SrcParam = null;
    MaterialProperty DstParam = null;
    MaterialProperty ZtestParam = null;


    // 折叠栏

    MaterialProperty MainTexWrap = null; // _MainTexWrap，用于材质级别的 U/V Repeat/Clamp 控制
    MaterialProperty MaskTexWrap = null; // _MaskTexWrap，用于材质级别的 U/V Repeat/Clamp 控制

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
        MainTexChannel = FindProperty("_MainTex_Channel", props, true); // 设置主贴图不同通道枚举
        MainTexColor = FindProperty("_Color", props, true);
        Glowintensity = FindProperty("_Glowintensity", props, true); // 发光强度
        UseCustomColor = FindProperty("_UseCustomColor", props, true); // 使用Custom控制强度变化 

        Power = FindProperty("_Power", props, true);
        Alpha = FindProperty("_Alpha", props, true);
        AorR = FindProperty("_AorR", props, true);
        UV_Polar_Main = FindProperty("_UV_Polar_Main", props, true);
        PolarMainTiling = FindProperty("_PolarMainTiling", props, true);

        SoftFade = FindProperty("_SoftFade", props, true);
        USE_Softparticle = FindProperty("_Toggle_USE_SOFTPARTICLE_ON", props, true);

        UVRot = FindProperty("_UVRot", props, true);
        MainTexAngle = FindProperty("_MainTexAngle", props, true);

        // 新增 Custom2 控制主贴图 UV 偏移
        UseCustom2MainUV = FindProperty("_UseCustom2MainUV", props, true);

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
        MaskTex_Channel = FindProperty("_MaskTex_Channel", props, true);  // 枚举
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
        MaskDistort = FindProperty("_MaskDistort", props, true);
        // Mask扭曲强度
        MaskDistortStrength = FindProperty("_MaskDistortStrength", props, true);


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

        Dissolve_Speed_U = FindProperty("_Dissolve_Speed_U", props, true);
        Dissolve_Speed_V = FindProperty("_Dissolve_Speed_V", props, true);

        // 属性 
        cullParam = FindProperty("_cull", props);
        SrcParam = FindProperty("_SrcBlend", props);
        DstParam = FindProperty("_DstBlend", props);
        ZtestParam = FindProperty("_zTest", props);

        // 折叠栏

        MainTexWrap = FindProperty("_MainTexWrap", props, false); // false 表示可选，不存在也不会报错
        MaskTexWrap = FindProperty("_MaskTexWrap", props, false); // 遮罩贴图 WrapMode (U,V)

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
    public GUILayoutOption[] shortButtonStyle = new GUILayoutOption[] { GUILayout.Width(100), GUILayout.Height(30) };
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
    // 主贴图

    void MainTex(Material mat)
    {

        EditorGUI.indentLevel++;

        // 🎨 大贴图槽（和 Unity 默认 Inspector 一致）
        m_MatEditor.TextureProperty(MainTex_Sample, "主贴图");
        DrawWrapModeUV(MainTexWrap, "主贴图 WrapMode (U,V)");


        m_MatEditor.ColorProperty(MainTexColor, "主贴图颜色");

        m_MatEditor.ShaderProperty(MainTexChannel, "主贴图通道选择");
        EditorGUILayout.Space(10);

        // 使用 R 作为 Alpha 通道

        bool texAorR_ON = EditorGUILayout.Toggle("使用R当Alpha通道", AorR.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            AorR.floatValue = texAorR_ON ? 1 : 0;
        }

        m_MatEditor.RangeProperty(Alpha, "Alpha");
        //m_MatEditor.TextureScaleOffsetProperty(MainTex_Sample);



        GUILayout.Space(10);
        m_MatEditor.RangeProperty(Power, "对比度");

        // 使用 Custom.w 控制强度变化
        EditorGUI.BeginChangeCheck();
        bool texCustom_ON = EditorGUILayout.Toggle("使用Custom.w控制强度变化", UseCustomColor.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            UseCustomColor.floatValue = texCustom_ON ? 1 : 0;
        }

        m_MatEditor.RangeProperty(Glowintensity, "发光强度");

        // UV 极坐标
        EditorGUI.BeginChangeCheck();
        bool uvPolar_ON = EditorGUILayout.Toggle("UV 极坐标(中心方向)", UV_Polar_Main.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            UV_Polar_Main.floatValue = uvPolar_ON ? 1 : 0;
        }
        if (UV_Polar_Main.floatValue == 1)
        {
            m_MatEditor.VectorProperty(PolarMainTiling, "极坐标缩放(Tiling: x, y; Offset: z, w)");
        }

        // 软粒子
        EditorGUI.BeginChangeCheck();
        bool soft_ON = EditorGUILayout.Toggle("软粒子", USE_Softparticle.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_Softparticle.floatValue = soft_ON ? 1 : 0;
        }
        if (USE_Softparticle.floatValue == 1)
        {
            mat.EnableKeyword("_USE_SOFTPARTICLE");
            m_MatEditor.RangeProperty(SoftFade, "柔和度");
        }
        else
        {
            mat.DisableKeyword("_USE_SOFTPARTICLE");
        }

        // UV旋转
        EditorGUI.BeginChangeCheck();
        bool uvRot_ON = EditorGUILayout.Toggle("贴图旋转 UV方向移动", UVRot.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            UVRot.floatValue = uvRot_ON ? 1 : 0;
        }

        if (UVRot.floatValue == 1)
        {
            EditorGUI.BeginChangeCheck();
            bool useCustom2 = EditorGUILayout.Toggle("使用 Custom2 控制主贴图UV", UseCustom2MainUV.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                UseCustom2MainUV.floatValue = useCustom2 ? 1 : 0;
            }

            if (UseCustom2MainUV.floatValue == 1)
            {
                EditorGUILayout.HelpBox("开启后：粒子 Custom2.xy 将用于控制主贴图 UV 偏移（Custom2.x -> U, Custom2.y -> V）。", MessageType.None);
            }

            m_MatEditor.RangeProperty(MainTexAngle, "纹理旋转");
            m_MatEditor.FloatProperty(UVSpeed_u, "纹理U方向速度");
            m_MatEditor.FloatProperty(UVSpeed_v, "纹理V方向速度");
        }

        // 整体换色
        EditorGUI.BeginChangeCheck();
        bool changeCol_ON = EditorGUILayout.Toggle("整体换色", USE_ChangeColor.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_ChangeColor.floatValue = changeCol_ON ? 1 : 0;
        }
        if (USE_ChangeColor.floatValue == 1)
        {
            mat.EnableKeyword("_USE_CHANGECOLOR");
            m_MatEditor.ColorProperty(ChangeColor, "换色");
        }
        else
        {
            mat.DisableKeyword("_USE_CHANGECOLOR");
        }
        EditorGUI.indentLevel--;

    }


    // 副纹理

    // ====================================================================================================================================
    // 副纹理
    void SecondaryTex(Material mat)
    {
        EditorGUI.indentLevel++;

        // 副纹理开关
        EditorGUI.BeginChangeCheck();
        bool useSecondary_ON = EditorGUILayout.Toggle("副纹理", USE_SecondaryTex_ON.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_SecondaryTex_ON.floatValue = useSecondary_ON ? 1 : 0;
        }

        EditorGUI.indentLevel--;

        if (USE_SecondaryTex_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_SECONDARYTEX");  // 打开变体

            m_MatEditor.TextureProperty(SecondaryTex_Sample, "副纹理");

            // 额外属性
            m_MatEditor.FloatProperty(SecondaryTex_Speed_U, "副纹理U方向速度");
            m_MatEditor.FloatProperty(SecondaryTex_Speed_V, "副纹理V方向速度");

            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_SECONDARYTEX");           // 关闭变体
        }

        EditorGUILayout.Space(10);
    }
    // ====================================================================================================================================

    // 遮罩
    void MaskTex(Material mat)
    {
        EditorGUI.indentLevel++;

        // 遮罩 Mask 开关
        EditorGUI.BeginChangeCheck();
        bool useMask_ON = EditorGUILayout.Toggle("遮罩Mask", USE_MASK_ON.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_MASK_ON.floatValue = useMask_ON ? 1 : 0;
        }

        EditorGUI.indentLevel--;

        if (USE_MASK_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_MASK");  // 打开变体

            m_MatEditor.TextureProperty(MaskTex_Sample, "Mask贴图");
            DrawWrapModeUV(MaskTexWrap, "Mask贴图 WrapMode (U,V)");

            m_MatEditor.ShaderProperty(MaskTex_Channel, "Mask贴图通道选择");
            m_MatEditor.ColorProperty(MaskTexColor, "遮罩系数");
            EditorGUILayout.Space(10);

            // 使用 R 当 Alpha 通道
            EditorGUI.BeginChangeCheck();
            bool useRasAlpha = EditorGUILayout.Toggle("使用R当Alpha通道", MaskTexAorR.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                MaskTexAorR.floatValue = useRasAlpha ? 1 : 0;
            }

            // UV 循环或一次性
            EditorGUI.BeginChangeCheck();
            bool _MASK_UVone_ON = EditorGUILayout.Toggle("UV循环或者一次性(默认循环)", MaskUV_one.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                MaskUV_one.floatValue = _MASK_UVone_ON ? 1 : 0;
            }

            if (MaskUV_one.floatValue == 1)
            {
                // 随粒子 Custom_Y 值 UV
                EditorGUI.BeginChangeCheck();
                bool useCustomY = EditorGUILayout.Toggle("随粒子Custom_Y值UV", MaskOne_UV.floatValue == 1);
                if (EditorGUI.EndChangeCheck())
                {
                    MaskOne_UV.floatValue = useCustomY ? 1 : 0;
                }

                m_MatEditor.RangeProperty(SpeedU, "纹理U方向");
                m_MatEditor.RangeProperty(SpeedV, "纹理V方向");
            }
            else
            {
                m_MatEditor.FloatProperty(Mask_UV_Speed_U, "纹理U方向速度");
                m_MatEditor.FloatProperty(Mask_UV_Speed_V, "纹理V方向速度");
            }

            // 遮罩 UV 偏移
            EditorGUI.BeginChangeCheck();
            bool useUvOffset = EditorGUILayout.Toggle("遮罩UV偏移", MaskUvOffsetMain.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                MaskUvOffsetMain.floatValue = useUvOffset ? 1 : 0;
            }
            if (MaskUvOffsetMain.floatValue == 1)
            {
                m_MatEditor.FloatProperty(MaskUvOffset, "遮罩UV偏移系数");
            }

            // 遮罩 UV 旋转
            EditorGUI.BeginChangeCheck();
            bool useRot = EditorGUILayout.Toggle("遮罩纹理UV 旋转", UVRot_Mask.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                UVRot_Mask.floatValue = useRot ? 1 : 0;
            }
            if (UVRot_Mask.floatValue == 1)
            {
                m_MatEditor.FloatProperty(MaskTexAngle, "遮罩纹理旋转");
                m_MatEditor.FloatProperty(MaskTexRotSpeed, "遮罩旋转速度");
            }

            // 遮罩扭曲
            EditorGUI.BeginChangeCheck();
            bool useDistort = EditorGUILayout.Toggle("遮罩开启扭曲", MaskDistort.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                MaskDistort.floatValue = useDistort ? 1 : 0;
            }
            if (MaskDistort.floatValue == 1)
            {
                m_MatEditor.RangeProperty(MaskDistortStrength, "遮罩扭曲强度");
            }

            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_MASK");  // 关闭变体
        }

        EditorGUILayout.Space(10);
    }


    // ====================================================================================================================================

    // 扭曲
    void DistortTex(Material mat)
    {
        EditorGUI.indentLevel++;

        // 扭曲开关
        EditorGUI.BeginChangeCheck();
        bool useDistort_ON = EditorGUILayout.Toggle("扭曲", USE_DISTORT_ON.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_DISTORT_ON.floatValue = useDistort_ON ? 1 : 0;
        }

        EditorGUI.indentLevel--;

        if (USE_DISTORT_ON.floatValue == 1)
        {
            mat.EnableKeyword("_USE_DISTORT"); // 打开变体
            EditorGUI.indentLevel++;

            m_MatEditor.TextureProperty(DistortTex_Sample, "扭曲贴图");
            //m_MatEditor.TextureScaleOffsetProperty(DistortTex_Sample);
            EditorGUILayout.Space(10);

            m_MatEditor.RangeProperty(DistortStrength, "扭曲强度");
            m_MatEditor.FloatProperty(DistortTex_Speed_U, "U 方向扭曲速度");
            m_MatEditor.FloatProperty(DistortTex_Speed_V, "V 方向扭曲速度");

            EditorGUILayout.Space(10);

            // 贴图 UV 旋转
            EditorGUI.BeginChangeCheck();
            bool disUVRot_ON = EditorGUILayout.Toggle("扭曲纹理uv 旋转", Dis_UVRot.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                Dis_UVRot.floatValue = disUVRot_ON ? 1 : 0;
            }

            if (Dis_UVRot.floatValue == 1)
            {
                m_MatEditor.FloatProperty(DisTexRotSpeed, "扭曲旋转速度");
            }

            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_DISTORT"); // 关闭变体
        }

        EditorGUILayout.Space(10);
    }


    // ====================================================================================================================================

    // 边缘光效果
    void Rim(Material mat)
    {
        EditorGUI.indentLevel++;

        // 开关改为 Begin/EndChangeCheck 包裹
        EditorGUI.BeginChangeCheck();
        bool rim_ON = EditorGUILayout.Toggle("边缘光", USE_RIM_ON.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_RIM_ON.floatValue = rim_ON ? 1 : 0;
        }

        EditorGUI.indentLevel--;

        if (USE_RIM_ON.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_RIM"); // 打开变体
            m_MatEditor.ColorProperty(RimColor, "边缘光颜色");
            m_MatEditor.RangeProperty(RimPower, "边缘光强度");
            m_MatEditor.FloatProperty(RimRevert, "边缘光反向");
            m_MatEditor.FloatProperty(RimAlpha, "边缘光Alpha反向");
            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_RIM"); // 关闭变体
        }

        EditorGUILayout.Space(10);
    }


    // ====================================================================================================================================

    // 溶解
    void DissolveTex(Material mat)
    {
        EditorGUI.indentLevel++;

        // 溶解开关
        EditorGUI.BeginChangeCheck();
        bool dissolve_ON = EditorGUILayout.Toggle("溶解", USE_DISSOLVE.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            USE_DISSOLVE.floatValue = dissolve_ON ? 1 : 0;
        }

        EditorGUI.indentLevel--;

        if (USE_DISSOLVE.floatValue == 1)
        {
            EditorGUI.indentLevel++;
            mat.EnableKeyword("_USE_DISSOLVE"); // 打开变体

            m_MatEditor.TextureProperty(DissolveTex_Sample, "溶解贴图");
            //m_MatEditor.TextureScaleOffsetProperty(DissolveTex_Sample);
            EditorGUILayout.Space(10);

            // 随粒子Custom值溶解
            EditorGUI.BeginChangeCheck();
            bool disAlpha_ON = EditorGUILayout.Toggle("随粒子Custom值溶解", DissolveAlpha.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                DissolveAlpha.floatValue = disAlpha_ON ? 1 : 0;
            }

            // 溶解开启扭曲
            EditorGUI.BeginChangeCheck();
            bool disDistort_ON = EditorGUILayout.Toggle("溶解开启扭曲", DissolveDistort.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                DissolveDistort.floatValue = disDistort_ON ? 1 : 0;
            }

            m_MatEditor.RangeProperty(DissolveStrength, "溶解度");
            m_MatEditor.ColorProperty(DissolveColor, "溶解边缘颜色");
            m_MatEditor.RangeProperty(DissolveWidth, "溶解边缘宽度");
            m_MatEditor.RangeProperty(DissolveSmooth, "边缘硬度");

            m_MatEditor.FloatProperty(Dissolve_Speed_U, "溶解U方向速度");
            m_MatEditor.FloatProperty(Dissolve_Speed_V, "溶解V方向速度");

            EditorGUI.indentLevel--;
        }
        else
        {
            mat.DisableKeyword("_USE_DISSOLVE"); // 关闭变体
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
            MaterialProperty[] props = { SrcParam, DstParam, cullParam, ZtestParam };
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


    // ===============================================================
    // 🎛 U/V WrapMode 控制器（Repeat / Clamp）
    // ===============================================================

    // Wrap 模式枚举（放在类里）
    enum TexWrapMode { Repeat = 0, Clamp = 1 }
    void DrawWrapModeUV(MaterialProperty prop, string label)
    {
        if (prop == null)
        {
            // 没有这个属性就不显示任何东西（兼容性更好）
            return;
        }

        if (prop.type != MaterialProperty.PropType.Vector)
        {
            EditorGUILayout.HelpBox($"Wrap 属性 {prop.name} 必须是 Vector 类型。", MessageType.Warning);
            return;
        }

        // 当前值 -> 枚举
        TexWrapMode wrapU = prop.vectorValue.x > 0.5f ? TexWrapMode.Clamp : TexWrapMode.Repeat;
        TexWrapMode wrapV = prop.vectorValue.y > 0.5f ? TexWrapMode.Clamp : TexWrapMode.Repeat;

        EditorGUILayout.BeginHorizontal();
        {
            // 左边 Label (主贴图 WrapMode)
            EditorGUILayout.LabelField(label, GUILayout.Width(120)); // 改宽度控制整体位置

            // U 设置
            //EditorGUILayout.LabelField("U", GUILayout.Width(20));
            GUILayout.Space(1); // 控制 U 和下拉之间距离
            wrapU = (TexWrapMode)EditorGUILayout.EnumPopup(wrapU, GUILayout.Width(180));

            GUILayout.Space(10); // 控制 U 和 V 整组之间的间距

            // V 设置
            //EditorGUILayout.LabelField("V", GUILayout.Width(20));
            GUILayout.Space(1);
            wrapV = (TexWrapMode)EditorGUILayout.EnumPopup(wrapV, GUILayout.Width(180));
        }
        EditorGUILayout.EndHorizontal();


        if (EditorGUI.EndChangeCheck())
        {
            prop.vectorValue = new Vector4(
                wrapU == TexWrapMode.Repeat ? 0f : 1f,
                wrapV == TexWrapMode.Repeat ? 0f : 1f,
                0f, 0f
            );

            // 通知 MaterialEditor 值已经改变（会刷新 Inspector）
            if (m_MatEditor != null) m_MatEditor.PropertiesChanged();
        }
    }

}

