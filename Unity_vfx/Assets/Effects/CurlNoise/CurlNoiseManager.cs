using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CurlNoiseManager : MonoBehaviour
{
    [SerializeField]
    MeshRenderer m_meshRenderer = default;



    [SerializeField]
    ComputeShader m_cs = default;

    [SerializeField]
    int m_dimension = 5; 

    Vector3[] m_motorDirs;

    RenderTexture rt;
    ComputeBuffer m_cbMotorDirs;
    ComputeBuffer m_cbDeltaTimes;
    ComputeBuffer m_cbEntityPos;

    ComputeBuffer m_cbEntityMoveDirs;

    ComputeBuffer  m_cbTestVal;

    void Start()
    {
        rt = new RenderTexture(m_dimension,m_dimension,0,RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        rt.enableRandomWrite = true;
        rt.autoGenerateMips = false;
        rt.filterMode = FilterMode.Point;
        rt.Create();

        m_meshRenderer.material.SetTexture("_MainTex",rt);

        const int motorsCount = 32;
        m_motorDirs = new Vector3[motorsCount];
        float[] DeltaTimes = new float[motorsCount];

        for(int i = 0; i < motorsCount; i++)
        {
            m_motorDirs[ i ]  =  Random.onUnitSphere;

            //float p = (i % m_dimension)/(float)m_dimension;
            //m_dirs[index] = new Vector3( Mathf.Cos( p*Mathf.PI*2.0f), -Mathf.Sin( p*Mathf.PI*2.0f) , 0.0f);
            //DeltaTimes[index] = p * 10;
            DeltaTimes[i] = Random.Range(0.0f,10.0f);
        }

        
        m_cbMotorDirs = new ComputeBuffer(motorsCount, sizeof(float)*3 );
        m_cbMotorDirs.SetData(m_motorDirs);
        
        m_cbDeltaTimes = new ComputeBuffer(motorsCount, sizeof(float) );
        m_cbDeltaTimes.SetData(DeltaTimes);

        const int entityCount = 10;
        Vector3[] entitiesPos = new Vector3[entityCount];
        Vector3[] entitiesMoveDirs = new Vector3[entityCount];
        for(int i = 0; i < entityCount; i++)
        {
            entitiesPos[i] = new Vector3(Random.Range(0.0f, m_dimension), Random.Range(0.0f, m_dimension), 0.0f);
            entitiesMoveDirs[i] = Random.onUnitSphere;
        }
        //Vector3 entityOrigPos = new Vector3(m_dimension/2.0f, m_dimension/2.0f, 0.0f);
        m_cbEntityPos = new ComputeBuffer(entityCount, sizeof(float)*3 );
        m_cbEntityPos.SetData(entitiesPos);

        m_cbEntityMoveDirs = new ComputeBuffer(entityCount, sizeof(float)*3 );
        m_cbEntityMoveDirs.SetData(entitiesMoveDirs);

        m_cs.SetBuffer(0, "deltaTimes", m_cbDeltaTimes);
        m_cs.SetBuffer(0, "motorDirs", m_cbMotorDirs);
        m_cs.SetBuffer(0, "entityPos", m_cbEntityPos);
        m_cs.SetBuffer(0, "entityMoveDirs", m_cbEntityMoveDirs);
        m_cs.SetTexture(0, "OutTex", rt);
        m_cs.SetFloat("_Dimension", m_dimension);

        uint[] testVal = new uint[]{1};
        m_cbTestVal = new ComputeBuffer(testVal.Length, sizeof(uint) );
        m_cbTestVal.SetData(testVal);
        m_cs.SetBuffer(0, "testFloats", m_cbTestVal);

        UpdateCurl();
    }

    [ContextMenu("UpdateCurl")]
    void UpdateCurl()
    {
        m_cs.SetFloat("_DeltaTime",Time.deltaTime);
        
//        int dimensionGroupCount = Mathf.CeilToInt( ((m_dimension) / 8.0f) );
        int ThreadGroupX = 4;
        int ThreadGroupY = 1;
        const int ThreadGroupZ = 1;
        
        m_cs.Dispatch(0, ThreadGroupX, ThreadGroupY, ThreadGroupZ);

        // Vector3[] outEntPos = new Vector3[10];
        // m_cbEntityPos.GetData(outEntPos);
        // Debug.Log(outEntPos[0]);

        uint[] outTestVals = new uint[1];
        m_cbTestVal.GetData(outTestVals);
        Debug.Log(outTestVals[0]);

    }

    /// <summary>
    /// This function is called when the MonoBehaviour will be destroyed.
    /// </summary>
    void OnDestroy()
    {
        m_cbDeltaTimes.Release();
        m_cbDeltaTimes = null;
        m_cbMotorDirs.Release();
        m_cbMotorDirs = null;
        m_cbEntityPos.Release();
        m_cbEntityPos = null;
        m_cbEntityMoveDirs.Release();
        m_cbEntityMoveDirs = null;

        rt.Release();
        rt= null;

    }

    // Update is called once per frame
    void Update()
    {
      //  UpdateCurl();
    }
}
