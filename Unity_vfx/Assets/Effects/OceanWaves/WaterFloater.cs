using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterFloater : MonoBehaviour
{
    [SerializeField]
    ComputeShader m_waterPointHeightSamplerCS = default;

    [SerializeField] float SampleFrequency = 0.1f;
    float m_timer = 0.0f;
    float m_sampledHeight;
    Quaternion m_sampledRotation;

    ComputeBuffer m_positionsBuffer;

    float m_oceanPatchSize = 100.0f;
    float m_oceanTexSize = 256.0f;
    bool initialized = false;

    public void Init(RenderTexture heightMap, float oceanPatchSize, float amplitude)
    {
        m_sampledHeight = this.transform.position.y;
        m_oceanPatchSize = oceanPatchSize;

        m_waterPointHeightSamplerCS.SetTexture(0, "Heightmap", heightMap);
        m_waterPointHeightSamplerCS.SetFloat("Amplitude", amplitude);
        m_oceanTexSize = heightMap.width;

        m_positionsBuffer = new ComputeBuffer(2, sizeof(float) * 2); 
        m_waterPointHeightSamplerCS.SetBuffer(0, "Positions", m_positionsBuffer);
        initialized = true;
    }

    // Update is called once per frame
    void Update()
    {
        if(!initialized)
        {
            return;
        }

        m_timer += Time.deltaTime;
        if( m_timer > SampleFrequency )
        {
            m_timer -= SampleFrequency;

            //Vector2 TextureSpacePointCoord = new Vector2(128,128);
            // Front
            Vector2 TextureSpacePointCoordFront = GetTextureSpaceCoordinate(this.transform.position + transform.forward * 2.0f);
            Vector2 TextureSpacePointCoordBack = GetTextureSpaceCoordinate(this.transform.position - transform.forward * 2.0f);
            
            m_positionsBuffer.SetData(new Vector2[]{TextureSpacePointCoordFront, TextureSpacePointCoordBack });
            
            m_waterPointHeightSamplerCS.Dispatch(0,1,1,1);

            Vector2[] ResultingHeightPositions = new Vector2[2];
            m_positionsBuffer.GetData(ResultingHeightPositions);
            // X is zero'd out, Y represents the sampled height

            //Average height of both sampled points
            m_sampledHeight = (ResultingHeightPositions[0].y +  ResultingHeightPositions[1].y) * 0.5f;

            Vector3 SampledFront = new Vector3(TextureSpacePointCoordFront.x, ResultingHeightPositions[0].y , TextureSpacePointCoordFront.y);
            Vector3 SampledBack = new Vector3(TextureSpacePointCoordBack.x, ResultingHeightPositions[1].y , TextureSpacePointCoordBack.y);
            Vector3 sampledForward = (SampledFront - SampledBack).normalized;

            m_sampledRotation = Quaternion.LookRotation(sampledForward, Vector3.up);
        }

        this.transform.rotation = Quaternion.Lerp(this.transform.rotation, m_sampledRotation, 0.35f);
        

        if( this.transform.position.y != m_sampledHeight)
        {
            Vector3 targetPos = new Vector3(this.transform.position.x, m_sampledHeight, this.transform.position.z);
            this.transform.position = Vector3.Lerp(this.transform.position, targetPos,0.2f );
        }

        this.transform.Translate( this.transform.right * 0.05f * Mathf.Sin(Time.time));
    }

    Vector2 GetTextureSpaceCoordinate(Vector3 worldSpaceCoordinate)
    {
        Vector2 TextureSpacePointCoord = new Vector2(worldSpaceCoordinate.x, worldSpaceCoordinate.z);
        TextureSpacePointCoord /= m_oceanPatchSize;
        TextureSpacePointCoord += new Vector2(0.5f,0.5f); // center
        TextureSpacePointCoord *= m_oceanTexSize;

        return TextureSpacePointCoord;
    }

    /// <summary>
    /// This function is called when the MonoBehaviour will be destroyed.
    /// </summary>
    void OnDestroy()
    {
        m_positionsBuffer.Release();   
    }
}
