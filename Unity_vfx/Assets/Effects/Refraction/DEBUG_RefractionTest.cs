using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DEBUG_RefractionTest : MonoBehaviour
{
    public Transform incidentRayorigin;
    public Vector3 incidentRay = Vector3.right;
    public Vector3 normal = Vector3.up;

    public float refractionIndex1 = 1;
    public float refractionIndex2 = 1;


    public Vector3 refractedVector1;
    public Vector3 refractedVector2;

    [ContextMenu("Normalize")]
    public void NormalizeNormal()
    {
        normal = normal.normalized;
    }

    public Vector3 Refract(float RI1, float RI2, Vector3 surfNorm, Vector3 incident)
    {
        surfNorm.Normalize(); //should already be normalized, but normalize just to be sure
        incident.Normalize();

        return (RI1 / RI2 * Vector3.Cross(surfNorm, Vector3.Cross(-surfNorm, incident)) - surfNorm * Mathf.Sqrt(1 - Vector3.Dot(Vector3.Cross(surfNorm, incident) * (RI1 / RI2 * RI1 / RI2), Vector3.Cross(surfNorm, incident)))).normalized;
    }

    private void OnDrawGizmos()
    {
        Vector3 origin = transform.position;

        Gizmos.color = Color.blue;
        Gizmos.DrawLine(origin, origin + normal);


        Gizmos.color = Color.green;
        incidentRay = (transform.position - incidentRayorigin.position).normalized ;
        Gizmos.DrawLine(incidentRayorigin.position, incidentRayorigin.position + incidentRay);

        refractedVector1 = Refract(refractionIndex1, refractionIndex2, normal, incidentRay).normalized;
        Gizmos.color = Color.red;
        Gizmos.DrawLine(origin , origin + refractedVector1);

        Gizmos.color = Color.blue;
        Vector3 normalExit = normal;
        Vector3 exitPoint = transform.position + refractedVector1;

        Gizmos.DrawLine(exitPoint, exitPoint + normalExit);

        refractedVector2 = Refract(refractionIndex2, refractionIndex1, normalExit, refractedVector1);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(exitPoint, exitPoint+ refractedVector2);

    }
}
