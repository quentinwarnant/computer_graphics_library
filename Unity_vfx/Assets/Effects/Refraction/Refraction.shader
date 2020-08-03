Shader "Q/Refraction"
{
    Properties
    {
		_ZTestMode ("ztest mode", float) = 0
		_CullMode("cull mode",float) = 0
    }
    SubShader
    {
        Pass
        {
			Name "Custom Depth Pass"

			Tags { "RenderType" = "Opaque" }
			LOD 100

			ZWrite On

			ZTest LEqual//[_ZTestMode]
			Cull [_CullMode]

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
                float4 pos : SV_POSITION;
				float4 worldPos: TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			float _ZTestMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos =  UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed maxDist = 4;
				float depth = 1 - (min(length(_WorldSpaceCameraPos - i.worldPos.xyz ),maxDist) / maxDist); 
				return fixed4(depth.x,0,0,1);
            }
            ENDCG
        }

		Pass
		{
			Name "Calculate Depth distance front and back"

			Tags { "RenderType" = "Opaque" }
			LOD 100

			//ZWrite On
			//ZTest LEqual

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

			struct fragOut {
				float4 color: SV_Target;
				float depth : SV_Depth;
			};

			sampler2D _DepthTex1;
			sampler2D _DepthTex2;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fragOut frag(v2f i)
			{
				float depth1 = tex2D(_DepthTex1,i.uv).r;
				float depth2 = tex2D(_DepthTex2,i.uv).r;

				fixed depth = (depth1 - depth2);
			
				fixed4 col = fixed4(depth.xxx,1);
				fragOut o;
				o.depth = depth;
				o.color = col;
				
				return o;
			}
			ENDCG
		}
    }
}
	