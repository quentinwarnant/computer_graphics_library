using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class DepthRender : UnityEngine.Rendering.Universal.ScriptableRendererFeature
{
    [System.Serializable]
    public class DepthRenderSettings
    {
        public RenderPassEvent When;
        public bool DepthInversed;
        public Shader DepthShader;
    }

    class DepthRenderPass : ScriptableRenderPass
    {
        string m_tag;
        DepthRenderSettings m_settings; 

        RenderTargetHandle m_QDepthTexture;
        RenderTextureDescriptor m_cameraTargetDesc;

        DrawingSettings m_drawingSettings;
        FilteringSettings m_filteringSettings;

        ShaderTagId m_ShaderTagId = new ShaderTagId("UniversalForward");

        RenderTargetIdentifier m_renderTargetIdentifier;

        Material m_depthMaterial;

        public DepthRenderPass(string tag, DepthRenderSettings settings)
        {
            m_tag = tag;
            m_settings = settings;
            // Configures where the render pass should be injected.
            renderPassEvent = settings.When;

            m_filteringSettings = new FilteringSettings(RenderQueueRange.opaque, -1);
            m_depthMaterial = new Material(settings.DepthShader);
            
        }

        public void Setup(RenderTextureDescriptor cameraTargetDesc, RenderTargetIdentifier renderTargetIdentifier, RenderTargetHandle RThandle)
        {
            m_cameraTargetDesc = cameraTargetDesc;
            m_cameraTargetDesc.colorFormat = RenderTextureFormat.ARGB32;
            //m_cameraTargetDesc.depthBufferBits = 32;

            m_renderTargetIdentifier = renderTargetIdentifier;
            m_QDepthTexture = RThandle;

        }

        // This method is called before executing the render pass. 
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in an performance manner.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var desc = m_cameraTargetDesc;
            cmd.GetTemporaryRT(m_QDepthTexture.id, desc.width, desc.height, cameraTextureDescriptor.depthBufferBits, FilterMode.Point);
            ConfigureTarget(m_QDepthTexture.Identifier());
            ConfigureClear(ClearFlag.Color, Color.black);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmdBuff = CommandBufferPool.Get(m_tag);
            using (new ProfilingScope(cmdBuff, new ProfilingSampler( m_tag ) ) )
            {
                context.ExecuteCommandBuffer(cmdBuff);
                cmdBuff.Clear();
                cmdBuff.name = m_tag;// "Blit Depth backwards";

                //Clear the Depth buffer with inversed value (so we can write GEqual into it)
                cmdBuff.ClearRenderTarget(true, false, Color.black, m_settings.DepthInversed ? 1.0f : 1.0f);
                context.ExecuteCommandBuffer(cmdBuff);
                cmdBuff.Clear();

                //Draw scene with depth material override
                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
                drawSettings.perObjectData = PerObjectData.None;

                ref CameraData cameraData = ref renderingData.cameraData;
                Camera camera = cameraData.camera;
                if (cameraData.isStereoEnabled)
                    context.StartMultiEye(camera);

                //4 = LEqual, 7 = GEqual
                m_depthMaterial.SetFloat("_ZTestMode", m_settings.DepthInversed ? 7 : 4);
                m_depthMaterial.SetFloat("_CullMode", m_settings.DepthInversed ? 1 : 2);
               // m_depthMaterial.SetFloat("_InverseDepthVal", m_settings.DepthInversed ? 1 : 0);

                drawSettings.overrideMaterial = m_depthMaterial;
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_filteringSettings);

                cmdBuff.SetGlobalTexture(m_settings.DepthInversed ? "_DepthNormalTexBack" : "_DepthNormalTexFront", m_QDepthTexture.id);

            }
            context.ExecuteCommandBuffer(cmdBuff);

            //cmdBuff.Clear();
            CommandBufferPool.Release(cmdBuff);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (m_QDepthTexture != RenderTargetHandle.CameraTarget)
            {
                cmd.ReleaseTemporaryRT(m_QDepthTexture.id);
                m_QDepthTexture = RenderTargetHandle.CameraTarget;
            }
        }
    }

    public DepthRenderSettings settings = new DepthRenderSettings();
    DepthRenderPass m_scriptablePass;
    RenderTargetHandle m_rthandle;

    public override void Create()
    {
        m_rthandle.Init("CustomDepthTex_" + (settings.DepthInversed ? "Inv" : "Reg" ));
        m_scriptablePass = new DepthRenderPass(name, settings);
    }
    
    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraTargetIdentifier = renderer.cameraColorTarget;
        var cameraTargetDesc = renderingData.cameraData.cameraTargetDescriptor;
        m_scriptablePass.Setup(cameraTargetDesc, cameraTargetIdentifier, m_rthandle);
        renderer.EnqueuePass(m_scriptablePass);
    }
}


