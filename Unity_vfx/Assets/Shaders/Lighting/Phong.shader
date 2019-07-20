Shader "Q/Lighting/Phong"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_LightCol ("Light Color", Color) = (1,1,1,1)

		_SpecularGloss("Spec Gloss",Float) = 1
		_SpecularPower("Spec Powoer",Float) = 1
		_SpecularColor("Spec Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" "RenderType"="Opaque" }
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
				float4 vertex : SV_POSITION;
				float3 color : COLOR;
			};

			float3 _LightCol;
			float3 _Color;
			
			float _SpecularGloss;
			float _SpecularPower;
			float3 _SpecularColor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				float3 vertexWorldPos = mul(v.vertex, unity_ObjectToWorld);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - vertexWorldPos);

				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				
				float3 lightReflectDir = reflect(worldNormal, -_WorldSpaceLightPos0);

				//Normal dot Light dir
				float3 NdotL = max(0,dot( worldNormal, _WorldSpaceLightPos0 ));
				
				//Reflection dot View
				float3 RdotV = max(0, dot( lightReflectDir, viewDir ) );

				float3 specularity = pow(RdotV, _SpecularGloss/4) * _SpecularPower * _SpecularColor.rgb;

				float3 litColor = (NdotL  * _Color) + specularity;
				litColor *= _LightCol;
				o.color = litColor;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = 1;
				col.rgb =  i.color;
				return col;
			}
			ENDCG
		}
	}
}
