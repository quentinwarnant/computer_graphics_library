using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class RenderFeature_DepthCalcFromTwoDepthBuffers : UnityEngine.Rendering.Universal.ScriptableRendererFeature
{
    [System.Serializable]
    public class RenderFeature_DepthCalcFromTwoDepthBuffersSettings
    {
        public RenderPassEvent When;
        public string DepthTex1Name;
        public string DepthTex2Name;
        public string DepthTexCombinedName;

        public Shader DepthShader;
        public int Pass;
    }

    class DepthCalcFromTwoDepthBuffersPass : ScriptableRenderPass
    {
        string m_tag;
        RenderFeature_DepthCalcFromTwoDepthBuffersSettings m_settings; 

        RenderTargetHandle m_combinedDepthTextureHandle;
        RenderTextureDescriptor m_cameraTargetDesc;
        RenderTargetIdentifier m_renderTargetIdentifier;
        Material m_depthMaterial;

        public DepthCalcFromTwoDepthBuffersPass(string tag, RenderFeature_DepthCalcFromTwoDepthBuffersSettings settings)
        {
            m_tag = tag;
            m_settings = settings;
            // Configures where the render pass should be injected.
            renderPassEvent = settings.When;

            m_depthMaterial = new Material(settings.DepthShader);
            
        }

        public void Setup(RenderTextureDescriptor cameraTargetDesc, RenderTargetHandle RThandle)
        {
            m_cameraTargetDesc = cameraTargetDesc;
            m_cameraTargetDesc.colorFormat = RenderTextureFormat.ARGB32;

            m_combinedDepthTextureHandle = RThandle;
        }

        // This method is called before executing the render pass. 
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in an performance manner.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var desc = m_cameraTargetDesc;
            cmd.GetTemporaryRT(m_combinedDepthTextureHandle.id, desc.width, desc.height);
            ConfigureTarget(m_combinedDepthTextureHandle.Identifier());
            ConfigureClear(ClearFlag.Depth, Color.black);

        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmdBuff = CommandBufferPool.Get(m_tag);

            using (new ProfilingScope(cmdBuff,  new ProfilingSampler( m_tag) ))
            {
                context.ExecuteCommandBuffer(cmdBuff);
                cmdBuff.Clear();
                cmdBuff.name = m_tag;

                cmdBuff.Blit(m_combinedDepthTextureHandle.Identifier(), m_combinedDepthTextureHandle.Identifier(), m_depthMaterial, m_settings.Pass);
                context.ExecuteCommandBuffer(cmdBuff);
                cmdBuff.Clear();

                cmdBuff.SetGlobalTexture(m_settings.DepthTexCombinedName, m_combinedDepthTextureHandle.id);

            }
            context.ExecuteCommandBuffer(cmdBuff);

            //cmdBuff.Clear();
            CommandBufferPool.Release(cmdBuff);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (m_combinedDepthTextureHandle != RenderTargetHandle.CameraTarget)
            {
                cmd.ReleaseTemporaryRT(m_combinedDepthTextureHandle.id);
                m_combinedDepthTextureHandle = RenderTargetHandle.CameraTarget;
            }
        }
    }

    public RenderFeature_DepthCalcFromTwoDepthBuffersSettings settings = new RenderFeature_DepthCalcFromTwoDepthBuffersSettings();
    DepthCalcFromTwoDepthBuffersPass m_scriptablePass;
    RenderTargetHandle m_rthandle;

    public override void Create()
    {
        m_rthandle.Init(settings.DepthTexCombinedName);
        m_scriptablePass = new DepthCalcFromTwoDepthBuffersPass(name, settings);
    }
    
    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraTargetDesc = renderingData.cameraData.cameraTargetDescriptor;
        m_scriptablePass.Setup(cameraTargetDesc, m_rthandle);
        renderer.EnqueuePass(m_scriptablePass);
    }
}


