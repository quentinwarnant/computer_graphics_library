using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class FluidSimManager : MonoBehaviour
{
    [SerializeField] ComputeShader m_fluidSimCS;

    [SerializeField] int m_volumeSize = 5;
    [SerializeField] float m_diffusion = 1.0f;
    [SerializeField] float m_viscosity = 0.1f;

    // 16 x 16 x 16 X 16 (threads) = 65536 cells in sim
    int m_dimensionGroupCount = 16;
    int m_cellsPerGroup = 8; // threads per group
        

    ComputeBuffer m_fluidPrevDensityBuffer;
    ComputeBuffer m_fluidDensityBuffer;
    ComputeBuffer m_fluidPrevVelocityBuffer;
    ComputeBuffer m_fluidVelocityBuffer;

    RenderTexture m_fluidRT;
    [SerializeField] MeshRenderer m_renderer;



    // Start is called before the first frame update
    void Start()
    {
        int N = m_dimensionGroupCount;
        int cellCount = N * N * N * m_cellsPerGroup;

        int sizeDensityData = sizeof(float);
        m_fluidPrevDensityBuffer = new ComputeBuffer(cellCount, sizeDensityData);
        m_fluidDensityBuffer = new ComputeBuffer(cellCount, sizeDensityData);
        InitDensityBuffersdata(m_fluidPrevDensityBuffer, cellCount );
        InitDensityBuffersdata(m_fluidDensityBuffer, cellCount );

        int sizeVelocityyData = sizeof(float) * 3;
        m_fluidPrevVelocityBuffer = new ComputeBuffer(cellCount, sizeVelocityyData);
        m_fluidVelocityBuffer = new ComputeBuffer(cellCount, sizeVelocityyData);
        InitVelocityBuffersdata(m_fluidPrevVelocityBuffer, cellCount );
        InitVelocityBuffersdata(m_fluidVelocityBuffer, cellCount );


        m_fluidSimCS.SetBuffer(0, "PrevDens", m_fluidPrevDensityBuffer);
        m_fluidSimCS.SetBuffer(0, "Dens", m_fluidDensityBuffer);
        m_fluidSimCS.SetBuffer(0, "PrevVel", m_fluidPrevVelocityBuffer);
        m_fluidSimCS.SetBuffer(0, "Vel", m_fluidVelocityBuffer);

        m_fluidSimCS.SetInt("Size", m_volumeSize);
        m_fluidSimCS.SetFloat("Diffusion", m_diffusion);
        m_fluidSimCS.SetFloat("Viscosity", m_viscosity);
        m_fluidSimCS.SetFloat("dt", 0);

        // Output
        int rtDimension = N * m_cellsPerGroup;
        RenderTextureDescriptor RTDesc = new RenderTextureDescriptor(rtDimension, rtDimension, RenderTextureFormat.RHalf, 0);
        RTDesc.dimension = TextureDimension.Tex3D;
        RTDesc.enableRandomWrite = true;
        RTDesc.volumeDepth = rtDimension;

        m_fluidRT = new RenderTexture(RTDesc);
        m_fluidRT.filterMode = FilterMode.Point;
        m_fluidRT.Create();

        m_fluidSimCS.SetTexture(0, "Result", m_fluidRT);

        m_renderer.material.SetTexture("_FluidSimTex", m_fluidRT);

    }

    void InitDensityBuffersdata(ComputeBuffer densityBuffer, int count)
    {
        float[] initialData = new float[count];
        densityBuffer.SetData(initialData);
    }

    void InitVelocityBuffersdata(ComputeBuffer velocityBuffer, int count)
    {
        float[] initialData = new float[count * 3];
        velocityBuffer.SetData(initialData);
    }

    // Update is called once per frame
    void Update()
    {
        m_fluidSimCS.SetFloat("dt", Time.deltaTime);
        m_fluidSimCS.SetFloat("time", Time.time);


        RunComputeShader();
    }

    void RunComputeShader()
    {
        int ThreadGroupX = m_dimensionGroupCount;
        int ThreadGroupY = m_dimensionGroupCount;
        int ThreadGroupZ = m_dimensionGroupCount;
        
        m_fluidSimCS.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    void OnDestroy()
    {
        m_fluidPrevDensityBuffer.Release();
        m_fluidDensityBuffer.Release();
        m_fluidPrevVelocityBuffer.Release();
        m_fluidVelocityBuffer.Release();

        m_fluidRT.Release();
        m_fluidRT = null;
    }

}
