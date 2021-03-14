// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Q/SubsurfaceScattering"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_SSSColor("SubSurfScat Color", Color) = (1,1,1,1)
		_SSSPower("SubSurfScat Power", Float) = 1
		_SSSScale("SubSurfScat Scale", Float) = 1
	}
	SubShader
	{
		

		//Tags{ "RenderType"="Transparent" "Queue"="Transparent"}
		//Blend SrcAlpha OneMinusSrcAlpha
		
		Pass
		{
			
			
			LOD 100


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD1;
				float3 normalWorld : NORMAL; 
				float4 color : COLOR;
				float inverseNDotL : TEXCOORD2;

			};

			float4 _Color;
			float4 _SSSColor;
			float _SSSPower;
			float _SSSScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				float3 vertexWorldPos = mul(v.vertex, unity_ObjectToWorld);
				o.viewDir =  _WorldSpaceCameraPos - vertexWorldPos;
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				//float3 lightDir = normalize( _WorldSpaceLightPos0.xyz - vertexWorldPos.xyz);



				float nDotL = saturate( dot( o.normalWorld, lightDir ) );
				float inverseNDotL =  saturate( dot( o.viewDir, -(lightDir + o.normalWorld)));
				float4 sssColor = ( inverseNDotL * _SSSColor);
				//sssColor = pow(sssColor, _SSSPower);
				//sssColor = dot(sssColor, _SSSScale);
				//sssColor = saturate(sssColor);

				o.color = (_Color *  ( nDotL))  + sssColor;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = i.color;

				
				return col;
			}
			ENDCG
		}
	}
}
