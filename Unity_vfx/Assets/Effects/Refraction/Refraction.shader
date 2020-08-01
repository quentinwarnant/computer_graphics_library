Shader "Q/Refraction"
{
    Properties
    {
		_ZTestMode ("ztest mode", float) = 0
    }
    SubShader
    {
        Pass
        {
			Name "Custom Depth Pass"

			Tags { "RenderType" = "Opaque" }
			LOD 100

			ZWrite On
			ZTest[_ZTestMode]
			Cull Off
			//ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 lighting : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			float _ZTestMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex =  UnityObjectToClipPos(v.vertex);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 NdotL = max(0,dot( worldNormal, _WorldSpaceLightPos0 ));
				
                o.lighting = (NdotL  * fixed3(1,1,1)); 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col = i.lighting + 0.5;
                return fixed4(col,1);
            }
            ENDCG
        }

		Pass
		{
			Name "Calculate Depth distance front and back"

			Tags { "RenderType" = "Opaque" }
			LOD 100

			ZWrite On
			ZTest Greater

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv: TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv: TEXCOORD0;
			};

			sampler2D _DepthTex1;
			float4 _DepthTex1_ST;
			sampler2D _DepthTex2;
			float4 _DepthTex2_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 depth1 = tex2D(_DepthTex1, i.uv);
				fixed4 depth2 = tex2D(_DepthTex2, i.uv);

				fixed depth = depth1.r - depth2.r;
				UNITY_OUTPUT_DEPTH(depth);
				return lerp(depth1, depth2,0.5);
			}
			ENDCG
		}
    }
}
	