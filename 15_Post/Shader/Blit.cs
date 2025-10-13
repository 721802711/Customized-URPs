using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class Blit : ScriptableRendererFeature
{
    [SerializeField] private Material material; // 指定用于颜色调节的材质

    private ColorAdjustRenderPass colorAdjustPass;

    public override void Create()
    {
        if (material == null)
        {
            Debug.LogWarning("ColorAdjustRendererFeature: 材质未赋值！");
            return;
        }

        colorAdjustPass = new ColorAdjustRenderPass(material)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (colorAdjustPass == null || material == null)
            return;

        if (renderingData.cameraData.cameraType != CameraType.Game)
            return;

        renderer.EnqueuePass(colorAdjustPass);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(material);
    }

    // 内嵌的渲染 Pass 类
    class ColorAdjustRenderPass : ScriptableRenderPass
    {
        private readonly Material material;
        private const string k_PassName = "ColorAdjustPass";

        public ColorAdjustRenderPass(Material material)
        {
            this.material = material;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var resourceData = frameData.Get<UniversalResourceData>();
            var cameraData = frameData.Get<UniversalCameraData>();

            if (resourceData.isActiveTargetBackBuffer || material == null)
                return;

            TextureHandle source = resourceData.activeColorTexture;

            if (!source.IsValid())
                return;

            // 使用第0个 Pass 渲染
            var passParams = new RenderGraphUtils.BlitMaterialParameters(
                source,
                source, // 直接写回源图（即屏幕）
                material,
                0
            );

            renderGraph.AddBlitPass(passParams, k_PassName);
        }
    }
}
