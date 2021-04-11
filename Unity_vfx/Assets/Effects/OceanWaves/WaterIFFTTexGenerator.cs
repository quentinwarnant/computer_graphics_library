using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class WaterIFFTTexGenerator : MonoBehaviour
{
    [SerializeField]
    MeshRenderer m_meshRendererH0K = default;

    [SerializeField]
    MeshRenderer m_meshRendererH0MinusK = default;

    [SerializeField]
    MeshRenderer m_meshRendererHKT_DY = default;
    [SerializeField]
    MeshRenderer m_meshRendererHKT_DX = default;

    [SerializeField]
    MeshRenderer m_meshRendererHKT_DZ = default;


    [SerializeField]
    MeshRenderer m_meshRendererButterflyTex = default;

    [SerializeField]
    MeshRenderer m_meshRendererPingPong0Tex = default;

    [SerializeField]
    MeshRenderer m_meshRendererPingPong1Tex = default;

    [SerializeField]
    MeshRenderer m_meshRendererHeightmapTex = default;

    [SerializeField]
    MeshRenderer m_meshRendererNormalmapTex = default;

    [SerializeField]
    MeshRenderer m_meshRendererOcean = default;

    [SerializeField] int N = 32; // sample count/Resolution
    [SerializeField] int L = 1024; // horizontal dimension of patch
    [SerializeField] float A = 10.0f; // "A Numeric constant  globally affecting heights of the waves"
    [SerializeField] Vector2 WindDir = Vector2.up;
    [SerializeField] float WindSpeed = 20.0f;
    


    [SerializeField]
    ComputeShader m_h0kcs = default;

    [SerializeField]
    ComputeShader m_FourierComponentcs = default;

    [SerializeField]
    ComputeShader m_TwiddleFactorcs = default;

    [SerializeField]
    ComputeShader m_ButterflyPasscs = default;

    [SerializeField]
    ComputeShader m_Inversioncs = default;

    [SerializeField]
    ComputeShader m_combineHeightMapChannelscs = default;

    [SerializeField]
    ComputeShader m_GenerateNormalMapcs = default;
    
    [SerializeField]
    float m_NormalStrength = 1.0f;

    

    RenderTexture rtTildeH0K;
    RenderTexture rtTildeH0MinusK;
    RenderTexture rtH0XT_dy; // Time dependant
    RenderTexture rtH0XT_dx; // Time dependant
    RenderTexture rtH0XT_dz; // Time dependant
    
    RenderTexture rtButterflyTex;

    //Butterfly pass
    RenderTexture rtPingPong0;
    RenderTexture rtPingPong1;
    
    RenderTexture rtHeightMapFinal; //Final output (x, y & z get combined  into it)
    RenderTexture rtHeightMap_y; 
    RenderTexture rtHeightMap_x; 
    RenderTexture rtHeightMap_z;
    
    RenderTexture rtNormalMap;

    

    [SerializeField] Texture2D m_noiseTex1 = default;
    [SerializeField] Texture2D m_noiseTex2 = default;
    [SerializeField] Texture2D m_noiseTex3 = default;
    [SerializeField] Texture2D m_noiseTex4 = default;

    ComputeBuffer  m_ButterflyBitReversedBuffer;
    int log_2_N;
    int m_pingPong;

    int[] m_reversedBits;

    //Consumers
    [SerializeField] WaterFloater m_surfer = default;


    void Start()
    {
        //--------------------------------------------------------------------
        // Initial frequency domain textures ~h0(k) & ~h0(-k)
        //--------------------------------------------------------------------
        rtTildeH0K = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtTildeH0K.enableRandomWrite = true;
        rtTildeH0K.autoGenerateMips = false;
        rtTildeH0K.filterMode = FilterMode.Point;
        rtTildeH0K.Create();

        m_meshRendererH0K.material.SetTexture("_MainTex",rtTildeH0K);


        rtTildeH0MinusK = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtTildeH0MinusK.enableRandomWrite = true;
        rtTildeH0MinusK.autoGenerateMips = false;
        rtTildeH0MinusK.filterMode = FilterMode.Point;
        rtTildeH0MinusK.Create();

        m_meshRendererH0MinusK.material.SetTexture("_MainTex",rtTildeH0MinusK);

        //--------------------------------------------------------------------
        // ~h(k,t) Displacements in frequency domain (x,y,z) - x & z for choppy waves
        //--------------------------------------------------------------------
        rtH0XT_dy = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtH0XT_dy.enableRandomWrite = true;
        rtH0XT_dy.autoGenerateMips = false;
        rtH0XT_dy.filterMode = FilterMode.Point;
        rtH0XT_dy.Create();

        m_meshRendererHKT_DY.material.SetTexture("_MainTex",rtH0XT_dy);

        rtH0XT_dx = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtH0XT_dx.enableRandomWrite = true;
        rtH0XT_dx.autoGenerateMips = false;
        rtH0XT_dx.filterMode = FilterMode.Point;
        rtH0XT_dx.Create();

        m_meshRendererHKT_DX.material.SetTexture("_MainTex",rtH0XT_dx);

        rtH0XT_dz = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtH0XT_dz.enableRandomWrite = true;
        rtH0XT_dz.autoGenerateMips = false;
        rtH0XT_dz.filterMode = FilterMode.Point;
        rtH0XT_dz.Create();

        m_meshRendererHKT_DZ.material.SetTexture("_MainTex",rtH0XT_dz);


        //--------------------------------------------------------------------
        // IFFT textures
        //--------------------------------------------------------------------
        log_2_N = (int) (Math.Log(N)/Math.Log(2));
        rtButterflyTex = new RenderTexture(log_2_N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtButterflyTex.enableRandomWrite = true;
        rtButterflyTex.autoGenerateMips = false;
        rtButterflyTex.filterMode = FilterMode.Point;
        rtButterflyTex.Create();

        m_meshRendererButterflyTex.material.SetTexture("_MainTex",rtButterflyTex);

        //Ping Pong 0
        rtPingPong0= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtPingPong0.enableRandomWrite = true;
        rtPingPong0.autoGenerateMips = false;
        rtPingPong0.filterMode = FilterMode.Point;
        rtPingPong0.Create();

        m_meshRendererPingPong0Tex.material.SetTexture("_MainTex",rtPingPong0);
        
        //Ping Pong 1
        rtPingPong1= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtPingPong1.enableRandomWrite = true;
        rtPingPong1.autoGenerateMips = false;
        rtPingPong1.filterMode = FilterMode.Point;
        rtPingPong1.Create();

        m_meshRendererPingPong1Tex.material.SetTexture("_MainTex",rtPingPong1);


        //--------------------------------------------------------------------
        // Result Heightmap
        //--------------------------------------------------------------------
        
        rtHeightMap_y= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtHeightMap_y.enableRandomWrite = true;
        rtHeightMap_y.autoGenerateMips = false;
        rtHeightMap_y.filterMode = FilterMode.Bilinear;
        rtHeightMap_y.Create();

        rtHeightMap_x= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtHeightMap_x.enableRandomWrite = true;
        rtHeightMap_x.autoGenerateMips = false;
        rtHeightMap_x.filterMode = FilterMode.Bilinear;
        rtHeightMap_x.Create();

        rtHeightMap_z= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtHeightMap_z.enableRandomWrite = true;
        rtHeightMap_z.autoGenerateMips = false;
        rtHeightMap_z.filterMode = FilterMode.Bilinear;
        rtHeightMap_z.Create();

        rtHeightMapFinal= new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtHeightMapFinal.enableRandomWrite = true;
        rtHeightMapFinal.autoGenerateMips = false;
        rtHeightMapFinal.filterMode = FilterMode.Bilinear;
        rtHeightMapFinal.Create();

        rtNormalMap = new RenderTexture(N,N,0,RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rtNormalMap.enableRandomWrite = true;
        rtNormalMap.autoGenerateMips = false;
        rtNormalMap.filterMode = FilterMode.Bilinear;
        rtNormalMap.Create();

        m_meshRendererHeightmapTex.material.SetTexture("_MainTex",rtHeightMapFinal);
        m_meshRendererNormalmapTex.material.SetTexture("_MainTex",rtNormalMap);


        //Assign to the actual ocean renderer material
        m_meshRendererOcean.material.SetTexture("_Heightmap",rtHeightMapFinal);
        m_meshRendererOcean.material.SetTexture("_NormalMap",rtNormalMap);
        

        //Original non time dependant values
        m_h0kcs.SetTexture(0, "noiseTex1", m_noiseTex1);
        m_h0kcs.SetTexture(0, "noiseTex2", m_noiseTex2);
        m_h0kcs.SetTexture(0, "noiseTex3", m_noiseTex3);
        m_h0kcs.SetTexture(0, "noiseTex4", m_noiseTex4);
        m_h0kcs.SetTexture(0, "OutTexTildeH0K", rtTildeH0K);
        m_h0kcs.SetTexture(0, "OutTexTildeH0MinusK", rtTildeH0MinusK);

        //Time dependant pass
        m_FourierComponentcs.SetTexture(0,"InTexH0k", rtTildeH0K);
        m_FourierComponentcs.SetTexture(0,"InTexH0Minusk", rtTildeH0MinusK);
        m_FourierComponentcs.SetTexture(0,"OutTexH0_XT_dy", rtH0XT_dy);
        m_FourierComponentcs.SetTexture(0,"OutTexH0_XT_dx", rtH0XT_dx);
        m_FourierComponentcs.SetTexture(0,"OutTexH0_XT_dz", rtH0XT_dz);
        
        //Butterfly
        m_ButterflyBitReversedBuffer = new ComputeBuffer(N, sizeof(int));
        m_TwiddleFactorcs.SetTexture(0, "OutButterflyTex",rtButterflyTex);


        m_reversedBits = GetReversedBits();

        RunSpectrumComputeShader();
        RunTwiddleFactorComputeShader();

        MeshFilter meshFilter = m_meshRendererOcean.GetComponent<MeshFilter>();
        //Assuming an even size & scale on horizontal plane
        float OceanSurfaceDimension = meshFilter.sharedMesh.bounds.size.x * m_meshRendererOcean.transform.localScale.x;
        m_surfer.Init(rtHeightMap_y, OceanSurfaceDimension, m_meshRendererOcean.material.GetFloat("_AmplitudeMult"));
    }

    int[] GetReversedBits()
    {
        int[] bitReversedIndices = new int[N];
		
		for (int i = 0; i<N; i++)
		{
			int x = i;
            int k = (int)CountBitsOfValue(N-1);
            // Binary representation of x of length k
            string binaryString = Convert.ToString(x, 2).PadLeft(k, '0');
            int reversed = Convert.ToInt32(Reverse(binaryString), 2);

            bitReversedIndices[i] = reversed;
		}
		
		return bitReversedIndices;
    }

    public static string Reverse( string s )
    {
        char[] charArray = s.ToCharArray();
        Array.Reverse( charArray );
        return new string( charArray );
    }

    uint CountBitsOfValue(int value)
    {
        return (uint)Math.Log(value , 2.0) + 1;
    }


    [ContextMenu("RunSpectrumComputeShader")]
    void RunSpectrumComputeShader()
    {
        m_h0kcs.SetInt("N",N);
        m_h0kcs.SetInt("L",L);
        m_h0kcs.SetFloat("A",A);
        m_h0kcs.SetVector("WindDir",WindDir);
        m_h0kcs.SetFloat("WindSpeed",WindSpeed);

        int dimensionGroupCount = Mathf.CeilToInt( (N / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;
        
        m_h0kcs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }


    [ContextMenu("RunH_KT_ComputeShader")]
    void RunH_KT_ComputeShader()
    {
        m_FourierComponentcs.SetInt("N",N);
        m_FourierComponentcs.SetInt("L",L);
        m_FourierComponentcs.SetFloat("t",500+Time.time);
       
        int dimensionGroupCount = Mathf.CeilToInt( (N / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;
        
        m_FourierComponentcs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    [ContextMenu("RunTwiddleFactorComputeShader")]
    void RunTwiddleFactorComputeShader()
    {
        m_ButterflyBitReversedBuffer.SetData(m_reversedBits);

        m_TwiddleFactorcs.SetBuffer(0, "bit_reversed",m_ButterflyBitReversedBuffer);
        m_TwiddleFactorcs.SetInt("N",N);

        int ThreadGroupX = log_2_N;
        int ThreadGroupY = Mathf.CeilToInt( N/16);
        const int ThreadGroupZ = 1;
        
        m_TwiddleFactorcs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    [ContextMenu("RunButterflyPassComputeShader")]
    void RunButterflyPassComputeShader()
    {
        int dimensionGroupCount = Mathf.CeilToInt( ((N) / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;

        m_ButterflyPasscs.SetTexture(0,"InButterflyTex",rtButterflyTex);
        m_ButterflyPasscs.SetTexture(0,"TexPingPong0",rtPingPong0);
        m_ButterflyPasscs.SetTexture(0,"TexPingPong1",rtPingPong1);

        m_pingPong = 0;
        
        // 1-D Horizontal FFT
        m_ButterflyPasscs.SetInt("direction",0);
        for (int i=0; i<log_2_N; i++)
        {
            m_ButterflyPasscs.SetInt("stage",i);
            m_ButterflyPasscs.SetInt("pingpong",m_pingPong);
        
            m_ButterflyPasscs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
            
            m_pingPong++;
            m_pingPong%=2;
        }

        // 1-D Vertical FFT
        m_ButterflyPasscs.SetInt("direction",1);
        for (int i=0; i<log_2_N; i++)
        {
            m_ButterflyPasscs.SetInt("stage",i);
            m_ButterflyPasscs.SetInt("pingpong",m_pingPong);
        
            m_ButterflyPasscs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
            
            m_pingPong++;
            m_pingPong%=2;
        }
    }


    [ContextMenu("RunInversionPassComputeShader")]
    void RunInversionPassComputeShader(RenderTexture heightMapTarget)
    {
        m_Inversioncs.SetInt("N",N);
        m_Inversioncs.SetInt("pingpong",m_pingPong);

        m_Inversioncs.SetTexture(0,"OutHeightDisplacement",heightMapTarget);
        m_Inversioncs.SetTexture(0,"TexPingPong0",rtPingPong0);
        m_Inversioncs.SetTexture(0,"TexPingPong1",rtPingPong1);

        int dimensionGroupCount = Mathf.CeilToInt( ((N) / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;
        
        m_Inversioncs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    void CombineHeightMapChannels()
    {
        m_combineHeightMapChannelscs.SetTexture(0, "DX", rtHeightMap_x);
        m_combineHeightMapChannelscs.SetTexture(0, "DY", rtHeightMap_y);
        m_combineHeightMapChannelscs.SetTexture(0, "DZ", rtHeightMap_z);
        m_combineHeightMapChannelscs.SetTexture(0, "CombinedTex", rtHeightMapFinal);

        int dimensionGroupCount = Mathf.CeilToInt( ((N) / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;
        
        m_combineHeightMapChannelscs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    void GenerateNormalMap()
    {
        m_GenerateNormalMapcs.SetTexture(0, "Heightmap", rtHeightMap_y);
        m_GenerateNormalMapcs.SetTexture(0, "Result", rtNormalMap);

        m_GenerateNormalMapcs.SetInt("N",N);
        m_GenerateNormalMapcs.SetFloat("NormalStrength",m_NormalStrength);

        int dimensionGroupCount = Mathf.CeilToInt( ((N) / 16.0f) );
        int ThreadGroupX = dimensionGroupCount;
        int ThreadGroupY = dimensionGroupCount;
        const int ThreadGroupZ = 1;
        
        m_GenerateNormalMapcs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);
    }

    void Update(){

        RunH_KT_ComputeShader();

        //for clarity we blit this resulting texture into PingPong0, 
        //but would be more efficient to just feed rtH0XT textures into pingPonging logic 
        Graphics.Blit( rtH0XT_dy ,rtPingPong0);
        RunButterflyPassComputeShader();
        RunInversionPassComputeShader(rtHeightMap_y);

        Graphics.Blit( rtH0XT_dx ,rtPingPong0);
        RunButterflyPassComputeShader();
        RunInversionPassComputeShader(rtHeightMap_x);

        Graphics.Blit( rtH0XT_dz ,rtPingPong0);
        RunButterflyPassComputeShader();
        RunInversionPassComputeShader(rtHeightMap_z);

        CombineHeightMapChannels();
        GenerateNormalMap();
    }


    /// <summary>
    /// This function is called when the MonoBehaviour will be destroyed.
    /// </summary>
    void OnDestroy()
    {
        rtTildeH0K.Release();
        rtTildeH0K= null;
        rtTildeH0MinusK.Release();
        rtTildeH0MinusK = null;
        rtH0XT_dy.Release();
        rtH0XT_dy = null;
        rtButterflyTex.Release();
        rtButterflyTex = null;
        rtPingPong0.Release();
        rtPingPong0 = null;
        rtPingPong1.Release();
        rtPingPong1 = null;

        rtHeightMap_y.Release();
        rtHeightMap_y = null;
        rtHeightMap_x.Release();
        rtHeightMap_x = null;
        rtHeightMap_z.Release();
        rtHeightMap_z = null;
        rtHeightMapFinal.Release();
        rtHeightMapFinal = null;
        rtNormalMap.Release();
        rtNormalMap = null;

        m_ButterflyBitReversedBuffer.Release();
    }
}
