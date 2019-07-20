Shader "Q/BloomPostFX"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BloomStrength("Bloom Strength", Range(0,1.5)) = 1
		_Radius("Bloom Radius", Range(0,4)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off
		ZTest Always
		ZWrite Off

		Pass 
		{
			Name "BLUR"

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

			float _BloomStrength;

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

				fixed emissiveValue = col.a;
				col.rgb = col.rgb * (emissiveValue * _BloomStrength);// * _BloomColor);

				return col;
			}
			ENDCG
		}


		Pass 
		{
			Name "COMBINE"


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

			sampler2D _BloomTex;
			float4 _BloomTex_TexelSize;
			float _Radius;

			float4 gaussianBlur(sampler2D tex, float2 dir, float2 uv, float res)
            {
                //this will be our RGBA sum
                float4 sum = float4(0, 0, 0, 0);
                
                //the amount to blur, i.e. how far off center to sample from 
                //1.0 -> blur by one pixel
                //2.0 -> blur by two pixels, etc.
                float blur = _Radius / res; 
                
                //the direction of our blur
                //(1.0, 0.0) -> x-axis blur
                //(0.0, 1.0) -> y-axis blur
                float hstep = dir.x;
                float vstep = dir.y;
                
                //apply blurring, using a 9-tap filter with predefined gaussian weights
                
                sum += tex2Dlod(tex, float4(uv.x - 4*blur*hstep, uv.y - 4.0*blur*vstep, 0, 0)) * 0.0162162162;
                sum += tex2Dlod(tex, float4(uv.x - 3.0*blur*hstep, uv.y - 3.0*blur*vstep, 0, 0)) * 0.0540540541;
                sum += tex2Dlod(tex, float4(uv.x - 2.0*blur*hstep, uv.y - 2.0*blur*vstep, 0, 0)) * 0.1216216216;
                sum += tex2Dlod(tex, float4(uv.x - 1.0*blur*hstep, uv.y - 1.0*blur*vstep, 0, 0)) * 0.1945945946;
                
                sum += tex2Dlod(tex, float4(uv.x, uv.y, 0, 0)) * 0.2270270270;
                
                sum += tex2Dlod(tex, float4(uv.x + 1.0*blur*hstep, uv.y + 1.0*blur*vstep, 0, 0)) * 0.1945945946;
                sum += tex2Dlod(tex, float4(uv.x + 2.0*blur*hstep, uv.y + 2.0*blur*vstep, 0, 0)) * 0.1216216216;
                sum += tex2Dlod(tex, float4(uv.x + 3.0*blur*hstep, uv.y + 3.0*blur*vstep, 0, 0)) * 0.0540540541;
                sum += tex2Dlod(tex, float4(uv.x + 4.0*blur*hstep, uv.y + 4.0*blur*vstep, 0, 0)) * 0.0162162162;

                return float4(sum.rgb, 1.0);
            }

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
				fixed4 cameraRenderCol = tex2D(_MainTex, i.uv);
				fixed4 bloomRTCol = tex2D(_BloomTex,i.uv);




				// lindenreid
				float resX = _BloomTex_TexelSize.z;
				float resY = _BloomTex_TexelSize.w;
				float4 blurX = gaussianBlur(_BloomTex, float2(1,0), i.uv, resX);
				float4 blurY = gaussianBlur(_BloomTex, float2(0,1), i.uv, resY);
				float4 glow = blurX + blurY;





				fixed4 col = cameraRenderCol + glow;

				return col;
			}
			ENDCG
		}
	}
}
