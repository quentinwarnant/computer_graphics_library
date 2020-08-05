using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode]
public class Rotator3D : MonoBehaviour
{
    [SerializeField]    Vector3 m_rotationDir;
    [SerializeField]    float m_rotSpeed = 1;


    // Update is called once per frame
    void Update()
    {
        this.transform.rotation *= Quaternion.Euler(m_rotationDir * m_rotSpeed);
    }
}
