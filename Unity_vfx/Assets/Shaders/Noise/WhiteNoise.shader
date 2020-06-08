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
			#include "../Random.cginc"

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

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

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
