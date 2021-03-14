Shader "Q/GersnerWave"
{
    Properties
    {
        _Color ("Color", COLOR) = (1,1,1,1)
        
		_LightCol ("Light Color", Color) = (1,1,1,1)

		_SpecularGloss("Spec Gloss",Float) = 1
		_SpecularPower("Spec Powoer",Float) = 1
		_SpecularColor("Spec Color", Color) = (1,1,1,1)

        //Wave
        _WaveA("Wave A Dir(XY), Length(Z), Steepness(W)",Vector) = (1,1,36,.8)
        _WaveB("Wave B Dir(XY), Length(Z), Steepness(W)",Vector) = (1,1,36,.8)
        _WaveC("Wave C Dir(XY), Length(Z), Steepness(W)",Vector) = (1,1,36,.8)
    }
    SubShader
    {
       

		Pass
		{
			Tags{ "RenderType"="Opaque"  "RenderPipeline" = "UniversalRenderPipeline" "LightMode" = "UniversalForward" }
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
                float3 vertexWorldPos : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
			};

            //Wave
            float4 _WaveA;
            float4 _WaveB;
            float4 _WaveC;

            //Lighting
			float3 _LightCol;
			float3 _Color;
			
			float _SpecularGloss;
			float _SpecularPower;
			float3 _SpecularColor;


            float3 GersnerWave(float4 WaveData, float3 vertPos, inout float3 tangent, inout float3 binormal )
            {
                float2 waveDir = normalize(WaveData.xy);

                float waveNumber = (UNITY_PI*2)/WaveData.z; //k
                float speed = sqrt(9.8 / waveNumber);//c - gravity / wave number
                float t = _Time.y; //t
                //kct - wavenumber movement amount per second

                float f = waveNumber * ( (dot(waveDir,vertPos.xz)) - (speed * t) );
                float steepnessMax = WaveData.w / waveNumber;//s

                //Normal calculation 
                tangent += float3(
                    (-1*waveDir.x) * waveDir.x * (WaveData.w * sin(f)),
                    waveDir.x * (WaveData.w * cos(f)),
                    (-1*waveDir.x) * waveDir.y * (WaveData.w * sin(f))
                );
                binormal += float3(
                    (-1*waveDir.x) * waveDir.y * (WaveData.w * sin(f)),
                    waveDir.y * (WaveData.w * cos(f)),
                    (-1*waveDir.y) * waveDir.y * (WaveData.w * sin(f))
                );

                return float3(
                    waveDir.x * steepnessMax * cos( f ),
                    steepnessMax * sin(  f ),
                    waveDir.y * steepnessMax * cos( f )
                );
            }

			v2f vert (appdata v)
			{
				v2f o;

                float3 origPos = v.vertex.xyz;
                float3 tangent = float3(1,0,0);
                float3 binormal = float3(0,0,1);
                float3 pos = origPos;
                pos+= GersnerWave(_WaveA, origPos, tangent, binormal);
                pos+= GersnerWave(_WaveB, origPos, tangent, binormal);
                pos+= GersnerWave(_WaveC, origPos, tangent, binormal);
                
                float3 normal = normalize(cross(binormal, tangent));
                v.normal = normal;

                o.vertex = UnityObjectToClipPos(pos);



                //PHONG SHADING
                o.vertexWorldPos = mul(pos, unity_ObjectToWorld);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.vertexWorldPos);
				o.worldNormal = UnityObjectToWorldNormal(normal);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

                //PHONG SHADING
				float3 vertexWorldPos = i.vertexWorldPos;
				float3 viewDir = i.viewDir;
				float3 worldNormal = i.worldNormal;
				float3 lightReflectDir = reflect(worldNormal, -_WorldSpaceLightPos0);

				//Normal dot Light dir
				float3 NdotL = max(0,dot( worldNormal, _WorldSpaceLightPos0 ));
				
				//Reflection dot View
				float3 RdotV = max(0, dot( lightReflectDir, viewDir ) );

				float3 specularity = pow(RdotV, _SpecularGloss/4) * _SpecularPower * _SpecularColor.rgb;

				float3 litColor = (NdotL  * _Color) + specularity;
				litColor *= _LightCol;
                

				// sample the texture
				fixed4 col = 1;
				col.rgb =  litColor;
				return col;
			}
			ENDCG
		}
	}
}
