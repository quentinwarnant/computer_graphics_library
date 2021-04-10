using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class PostFXBloom : MonoBehaviour 
{
	Camera m_cam;

	[SerializeField] RenderTexture m_targetRT = default;
	[SerializeField] Material m_postFXMat = default;

	[ContextMenu("Init")]
	public void Init()
	{
		m_cam = GetComponent<Camera>();

		Shader.SetGlobalTexture("_BloomTex",m_targetRT);


		CommandBuffer buffer = new UnityEngine.Rendering.CommandBuffer();
		buffer.name = "PostFXBloom Buffer";
		int blurPass = m_postFXMat.FindPass("BLUR");
		Debug.Log("blur pass index: " + blurPass);
		buffer.Blit( BuiltinRenderTextureType.CameraTarget, m_targetRT, m_postFXMat,blurPass);
		m_cam.AddCommandBuffer(UnityEngine.Rendering.CameraEvent.AfterForwardAlpha, buffer);

		CommandBuffer combineBloomAndFinalCameraRenderBuffer = new UnityEngine.Rendering.CommandBuffer();
		combineBloomAndFinalCameraRenderBuffer.name = "Apply Bloom to Final Render Buffer";
		
		int combinePass = m_postFXMat.FindPass("COMBINE");
		Debug.Log("combine pass index: " + combinePass);
		combineBloomAndFinalCameraRenderBuffer.Blit( BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget,m_postFXMat, combinePass);
		m_cam.AddCommandBuffer(UnityEngine.Rendering.CameraEvent.AfterForwardAlpha + 1, combineBloomAndFinalCameraRenderBuffer);
	}

	// Use this for initialization
	void Start () 
	{
		Init();	
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
