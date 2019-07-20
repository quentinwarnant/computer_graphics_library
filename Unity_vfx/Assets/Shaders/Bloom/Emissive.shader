Shader "Q/Emissive"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_EmissiveTex ("Emissive Map", 2D) = "black" {}
		_EmissiveCol("Emissive Color", COLOR) = (1,1,1,1)
		
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
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _EmissiveTex;
			float4 _EmissiveTex_ST;

			float4 _EmissiveCol;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed emissive = tex2D(_EmissiveTex, i.uv).r;

				col += emissive * _EmissiveCol;

				//using alpha channel for bloom effect
				col.a = emissive;

				return col;
			}
			ENDCG
		}
	}
}
