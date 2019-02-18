using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomRotator : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        this.transform.rotation = Quaternion.Euler(
                                        Random.Range(0.0f,360.0f),
                                        Random.Range(0.0f,360.0f),
                                        Random.Range(0.0f,360.0f)
                                        );
    }

}
