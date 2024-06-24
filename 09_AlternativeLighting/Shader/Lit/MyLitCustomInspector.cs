using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class MyLitCustomInspector : ShaderGUI
{
    public enum SurfaceType
    {
        Opaque, TransparentBlend,TransparentCutout 
    }

    public enum FaceRenderingMode
    {
        FrontOnly, NoCulling, DoubleSided
    }

    // 创建一个枚举类型，用于选择混合模式
    public enum BlendType 
    {
        Alpha, Premultiplied, Additive, Multiply
    }
    


    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);

        if(newShader.name == "URP/MyLit")
        {
            UpdateSurfaceType(material);
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {

        Material material = materialEditor.target as Material;
        var surfaceProp = BaseShaderGUI.FindProperty("_SurfaceType", properties, true);
        var blendProp = BaseShaderGUI.FindProperty("_BlendType", properties, true);
        var faceProp = BaseShaderGUI.FindProperty("_FaceRenderingMode", properties, true);
        
        EditorGUI.BeginChangeCheck();
        surfaceProp.floatValue = (int)(SurfaceType)EditorGUILayout.EnumPopup("Surface type", (SurfaceType)surfaceProp.floatValue);
        blendProp.floatValue = (int)(BlendType)EditorGUILayout.EnumPopup("Blend type", (BlendType)blendProp.floatValue);
        faceProp.floatValue = (int)(FaceRenderingMode)EditorGUILayout.EnumPopup("Face rendering mode", (FaceRenderingMode)faceProp.floatValue);
        base.OnGUI(materialEditor, properties);

        if(EditorGUI.EndChangeCheck()) {
            UpdateSurfaceType(material);
        }

    }

    private void UpdateSurfaceType(Material material)
    {
        SurfaceType surface = (SurfaceType)material.GetFloat("_SurfaceType");
        switch(surface)
        {
            case SurfaceType.Opaque:
                material.renderQueue = (int)RenderQueue.Geometry;
                material.SetOverrideTag("RenderType", "Opaque");
                break;
            case SurfaceType.TransparentCutout:
                material.renderQueue = (int)RenderQueue.AlphaTest;
                material.SetOverrideTag("RenderType", "TransparentCutout");
                break;
            case SurfaceType.TransparentBlend:
                material.renderQueue = (int)RenderQueue.Transparent;
                material.SetOverrideTag("RenderType", "Transparent");
                break;
        }
        // 获取混合模式
        BlendType blend = (BlendType)material.GetFloat("_BlendType");
        switch(surface) {
        case SurfaceType.Opaque:
        case SurfaceType.TransparentCutout:
            material.SetInt("_SourceBlend", (int)BlendMode.One);
            material.SetInt("_DestBlend", (int)BlendMode.Zero);
            material.SetInt("_ZWrite", 1);
            break;
        case SurfaceType.TransparentBlend:
            switch(blend) {
            case BlendType.Alpha:
                material.SetInt("_SourceBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DestBlend", (int)BlendMode.OneMinusSrcAlpha);
                break;
            case BlendType.Premultiplied:
                material.SetInt("_SourceBlend", (int)BlendMode.One);
                material.SetInt("_DestBlend", (int)BlendMode.OneMinusSrcAlpha);
                break;
            case BlendType.Additive:
                material.SetInt("_SourceBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DestBlend", (int)BlendMode.One);
                break;
            case BlendType.Multiply:
                material.SetInt("_SourceBlend", (int)BlendMode.Zero);
                material.SetInt("_DestBlend", (int)BlendMode.SrcColor);
                break;
            }
            material.SetInt("_ZWrite", 0);
            break;
        }
        material.SetShaderPassEnabled("ShadowCaster", surface != SurfaceType.TransparentBlend);

        if(surface == SurfaceType.TransparentCutout)
        {
            material.EnableKeyword("_ALPHA_CUTOUT");
        }
        else
        {
            material.DisableKeyword("_ALPHA_CUTOUT");
        }
        if(surface == SurfaceType.TransparentBlend && blend == BlendType.Premultiplied) {
            material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
        } else {
            material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        }

        // 设置法线贴图 
        if(material.GetTexture("_NormalMap") == null)
        {
            material.DisableKeyword("_NORMALMAP");
        }
        else
        {
            material.EnableKeyword("_NORMALMAP");
        }

        // 设置双面显示
        FaceRenderingMode faceRenderingMode = (FaceRenderingMode)material.GetFloat("_FaceRenderingMode");
        if(faceRenderingMode == FaceRenderingMode.FrontOnly)
        {
            material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Back);
        }
        else
        {
            material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
        }

        if(faceRenderingMode == FaceRenderingMode.DoubleSided)
        {
            material.EnableKeyword("_DOUBLE_SIDED_NORMALS");
        }
        else
        {
            material.DisableKeyword("_DOUBLE_SIDED_NORMALS");
        }
    }
}