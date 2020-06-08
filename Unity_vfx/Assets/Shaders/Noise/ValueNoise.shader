Shader "Q/Noise/ValueNoise"
{
	Properties
	{
		_CellSize("Cell Size", Vector) = (1,1,1,1)
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
			
			inline float EaseIn(float interpolator)
			{
				return interpolator * interpolator;
			}
			
			inline float EaseOut(float interpolator)
			{
				return 1 - EaseIn( 1- interpolator);
			}
			
			float EaseInOut( float interpolator )
			{
				float valueEaseIn = EaseIn(interpolator);
				float valueEaseOut = EaseOut(interpolator);
				return lerp(valueEaseIn, valueEaseOut, interpolator);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul( unity_ObjectToWorld, v.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col =  1;

				float worldValue = i.worldPos.x / _CellSize;

				//Interpoltaion between two full values
				float previousCellValue = Random1dto1d(floor(worldValue));
				float nextCellValue = Random1dto1d(ceil(worldValue));
				float interpolator = EaseInOut(frac(worldValue));
				float interpolatedValue = lerp( previousCellValue, nextCellValue, interpolator);
				float distance = abs( interpolatedValue - i.worldPos.y );


				// fwidth compares the difference between neighbouring fragments
				// the value is irrespective of view distance, use eg: for edges 
				float lineWidth = fwidth(i.worldPos.y);
				float value = smoothstep(0,lineWidth, distance);




				col.rgb =   fixed3((1-value),value * 0.6,0);

				return col;
			}
			ENDCG
		}
	}
}
