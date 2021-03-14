// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Q/FireVolume"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_DistortionTex("Distortion Tex", 2D) = "white" {}

		_ScrollSpeed("ScrollSpeeds (X,Y)", Vector) = (0,0,0,0)

		_Intensity("Fire Intensity", Range(0,3)) = 0

		_AlphaMult("Alpha Multiplier", Range(0,1) ) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 uvWithOffsets : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float visibility : TEXCOORD2;

				float3  wsNormal : NORMAL;
				float3 worldPos : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _DistortionTex;
			float4 _DistortionTex_ST;

			float4 _ScrollSpeed;
			
			float _Intensity;

			float _AlphaMult;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv = uv;
				o.uvWithOffsets.xy = uv;
				o.uvWithOffsets.zw = uv;

				o.uvWithOffsets.xy = (o.uvWithOffsets.xy + float2( ( _Time.x * _ScrollSpeed.x), ( _Time.x * _ScrollSpeed.y) ) );
				o.uvWithOffsets.zw = (o.uvWithOffsets.zw + float2( ( _Time.x * _ScrollSpeed.z) ,  ( _Time.x * _ScrollSpeed.w) ) );

				o.wsNormal = normalize( UnityObjectToWorldNormal(v.normal) );
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 uvDistortionSample =(tex2D(_DistortionTex, i.uv ) );
				float uvDistortion = uvDistortionSample.x/ 100;

				fixed4 col1 = tex2D(_MainTex, i.uvWithOffsets.xy + uvDistortion);
				fixed4 col2 = tex2D(_MainTex, i.uvWithOffsets.zw + uvDistortion);
				fixed4 col3 = tex2D(_MainTex, i.uvWithOffsets.xw + uvDistortion);

//				fixed4 col = (col1 + col2)  / (2 -_Intensity);
//				fixed4 col = lerp(col1, col2, uvDistortionSample.r +1 );
				fixed4 col = max(max(col1, col2), col3);
				
				col *= _Intensity;

				//Rim Alpha
				float3 wsViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				col.a = pow( dot(i.wsNormal, wsViewDir) , 2) * _AlphaMult;

				return col;
			}
			ENDCG
		}
	}
}
