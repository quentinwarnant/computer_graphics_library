Shader "Q/Disolve"
{
	Properties
	{
		_CullMode("Cull Mode",float) = 0 // 0: none, 1: front, 2 : back

		_MainTex ("Texture", 2D) = "white" {}
		_DisolveTex("Disolve Map",2D) = "white" {}
		[HDR]
		_DisolveCol("Disolve Color", COLOR) = (2,2,2,1)
		_DisolveAmount("Disolve Amount", Range(0,1)) = 0
		_DisolveEdgeSize("Disolve Edge Size", Range(0,1.5)) = 0.2

	}

	SubShader
	{
		Tags
		{
			// "RenderType"="Opaque", 
			"Queue" = "Transparent"
            "RenderType" = "Transparent"
            
		}

		Cull [_CullMode]

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
			
			sampler2D _DisolveTex;
			float4 _DisolveTex_ST;

			float4 _DisolveCol;

			float _DisolveAmount;
			float _DisolveEdgeSize;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				_DisolveAmount = _DisolveAmount * 3;

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed disolveValue = tex2D(_DisolveTex,i.uv).r;

				disolveValue += 2*i.uv.y;
				
				float scaledDisolveAmount = (_DisolveAmount *  (1 + _DisolveEdgeSize))- _DisolveEdgeSize;



				if( disolveValue < scaledDisolveAmount + (_DisolveEdgeSize/2))
				{
					clip(-1);
				}
				else 
				{
					col += (1-smoothstep(scaledDisolveAmount, scaledDisolveAmount+_DisolveEdgeSize, disolveValue) ) * _DisolveCol;

				}
 
				return col;
			}
			ENDCG
		}
	}
}
