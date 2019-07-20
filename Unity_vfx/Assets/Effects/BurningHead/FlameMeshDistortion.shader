Shader "Q/FlameMeshDistortion"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DistortionTex("Distortion Map",2D) = "white" {}
		_DistortionSpeed("Vertex Distortion Speed (2 samples)", Vector) = (0,0,0,0)
		_DistortionDir("Vertex Distortion Direction (X,Y,Z)", Vector) = (0,0,0,0)
		_TextureScrollSpeed("Texture scroll speed (X,Y)", Vector) = (0,0,0,0)

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

			sampler2D _DistortionTex;
			float4 _DistortionTex_ST;

			float4 _DistortionSpeed;
			float4 _DistortionDir;

			float2 _TextureScrollSpeed;
			
			v2f vert (appdata v)
			{
				v2f o;

				//distort vertices in local space
				v.vertex +=  float4(
					 sin( v.vertex.x * _DistortionDir.x * _DistortionSpeed.x * _Time.y) * _DistortionSpeed.y,
					 sin( v.vertex.y * _DistortionDir.y * _DistortionSpeed.z * _Time.y) * _DistortionSpeed.w,
					 0,0);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
