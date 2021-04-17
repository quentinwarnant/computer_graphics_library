using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDolly : MonoBehaviour
{
    [SerializeField] Transform m_target = default;
    Vector3 m_idealDistanceNormalizedDir;
    float m_idealDistance;
    [SerializeField, Range(1,40)] float m_distanceMult = 1.0f; 

    [SerializeField] float m_lerpingRate = 0.5f;

    // Start is called before the first frame update
    void Start()
    {
        Vector3 idealDistanceVector =  this.transform.position - m_target.position;
        m_idealDistanceNormalizedDir = idealDistanceVector.normalized;
        m_idealDistance = idealDistanceVector.magnitude;
    }

    // Update is called once per frame
    void Update()
    {
        float currentOffsetDist = (m_target.position - this.transform.position).magnitude;
        float lerpedDist  = Mathf.Lerp(currentOffsetDist, m_idealDistance * m_distanceMult, m_lerpingRate);

        this.transform.position = m_target.position + m_idealDistanceNormalizedDir * lerpedDist;
    }
}
