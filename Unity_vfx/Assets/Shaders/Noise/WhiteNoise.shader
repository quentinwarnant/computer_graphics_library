Shader "Q/Noise/WhiteNoise"
{
	Properties
	{
		_CellSize ("Cell Size", Vector) = (1,1,1,0)
		_Offset("OFFSET",Vector) = (1,1,1,1)

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
			};

			float3 _CellSize;
			float3 _Offset;

			float Random3dTo1d(float3 vec, float3 dotDir = float3(42.04, 21.251, 11.501))
			{
				// Reduce scope of value, to avoid artefacts.
				vec = sin(vec);
				float result = dot(vec, dotDir);

				// Sin is again used to reduce scope, to avoid hitting float precision limit
				result = frac( sin(result) * 59442.11230);

				return result;
			}

			float3 Random3dTo3d(float3 vec)
			{
				float3 result;
				result.x = Random3dTo1d(vec, float3(42.04, 21.251, 11.501));
				result.y = Random3dTo1d(vec, float3(12.44, 91.651, 44.105));
				result.z = Random3dTo1d(vec, float3(4.04, 1.251, 156.671));

				return result;
			}
			

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.worldPos = mul(v.vertex, unity_ObjectToWorld);

				o.worldPos += _Offset;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = 1;

				float3 worldPos = ceil(i.worldPos / _CellSize);
				col.rgb = Random3dTo3d(worldPos);

				return col;
			}

			ENDCG
		}
	}
}
