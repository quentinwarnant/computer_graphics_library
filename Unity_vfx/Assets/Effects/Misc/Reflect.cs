using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Reflect : MonoBehaviour
{

    public     Vector3 incomingVector = new Vector3(0.5f, -1, 0);
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 normal = this.transform.up;

        Vector3 reflectedVector = incomingVector - 2*( Vector3.Dot(incomingVector, normal)) * normal;

        Debug.DrawRay(Vector3.zero - incomingVector, incomingVector, Color.red);
        Debug.DrawRay(Vector3.zero,normal, Color.green);
        Debug.DrawRay(Vector3.zero, Vector3.zero + reflectedVector, Color.blue);
        
    }
}
