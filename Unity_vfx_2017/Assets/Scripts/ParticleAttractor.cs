using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleAttractor : MonoBehaviour 
{
	[SerializeField] ParticleSystem m_particleSystem;
	ParticleSystem.Particle[] m_particles;
	[SerializeField] float m_radius = 5;

	[SerializeField] float m_rotationSpeed;

	[SerializeField] [Range(0,1)] float m_lerpToCore = 0;

	[SerializeField] [Range(0,1)] float m_speedPowMax = 4;

	[ContextMenu("Start")]
	// Use this for initialization
	void Start () 
	{
		m_particles = new ParticleSystem.Particle[m_particleSystem.main.maxParticles];
	}
	
	// Update is called once per frame
	void Update ()
	{
		float radiusSqr = m_radius * m_radius;

		int particleCount = m_particleSystem.GetParticles(m_particles);
		for(int i = 0; i < particleCount; i++)
		{
			Vector3 vecParticleToParticleSystem = (m_particleSystem.transform.position - m_particles[i].position);
			float distanceSqr = (m_particles[i].position - m_particleSystem.transform.position).sqrMagnitude;
			if( distanceSqr < (radiusSqr))
			{
				//float magnitude = m_particles[i].velocity.magnitude;
				float magnitude = Mathf.Pow(vecParticleToParticleSystem.magnitude, Mathf.Lerp(.2f,m_speedPowMax,(radiusSqr / vecParticleToParticleSystem.sqrMagnitude)) ) * m_rotationSpeed;
				


				Vector3 upVector = (new Vector3(m_particles[i].randomSeed % 200, m_particles[i].randomSeed % 563, m_particles[i].randomSeed % 278)).normalized;
				Vector3 newVelocityVector = Vector3.Cross(upVector, vecParticleToParticleSystem.normalized );

				newVelocityVector = Vector3.Lerp(newVelocityVector, vecParticleToParticleSystem.normalized, m_lerpToCore );

				//Debug.DrawRay(m_particles[i].position, newVelocityVector * magnitude, Color.red);

				/* 
				(m_particles[i].velocity.normalized 
				+  new Vector3(
					Mathf.Sin(m_rotationSpeed * Time.timeSinceLevelLoad),
					0,
//					 m_particleRotation.y * Time.deltaTime,
					Mathf.Cos(m_rotationSpeed * Time.timeSinceLevelLoad)
					 ).normalized).normalized;
				*/
				m_particles[i].velocity = newVelocityVector * magnitude;
			}
		}
		m_particleSystem.SetParticles(m_particles,particleCount);

	}

	private void OnDrawGizmos() 
	{
		Gizmos.DrawWireSphere(m_particleSystem.transform.position, m_radius);	
	}
}
