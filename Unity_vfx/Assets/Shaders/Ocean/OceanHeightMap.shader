Shader "Q/OceanHeightMap"
{
    Properties
    {
        _Color("Base",COLOR) = (1,1,1,0)
        _Heightmap ("Heightmap", 2D) = "white" {}
        _NormalMap ("Normal", 2D) = "white" {}

        _AmplitudeMult("Amplitude",Range(0,50)) = 2
        _Choppiness("Choppiness",Range(0,10)) = 1

        _LightCol("LightCol",COLOR) = (1,1,1,0)
        _LightIntensity("Light Intensity",Range(0.1,4) ) = 1

        _SpecularGloss("Spec Gloss",Float) = 1
		_SpecularPower("Spec Powoer",Float) = 1
		_SpecularColor("Spec Color", Color) = (1,1,1,1)

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

            sampler2D _Heightmap;
            float4 _Heightmap_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            
            float4 _Color;
            float3 _LightCol;
            float _LightIntensity;

			float _SpecularGloss;
			float _SpecularPower;
			float3 _SpecularColor;


            float _AmplitudeMult;
            float _Choppiness;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;

                float4 heightMap = tex2Dlod (_Heightmap, float4(v.uv.xy ,0,0));
                v.vertex.y += heightMap.y * _AmplitudeMult;
                v.vertex.xz -= heightMap.xz * _Choppiness;

                o.vertex = UnityObjectToClipPos(v.vertex);

                //Lighting
                float3 vertexWorldPos = mul(v.vertex, unity_ObjectToWorld);
                o.viewDir = normalize(_WorldSpaceCameraPos.xyz - vertexWorldPos);

				

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = float4(1,1,1,1);

                //------------//
                //  Lighting  //
                //------------//

                //Diffuse
                float3 normal = tex2D(_NormalMap, i.uv).rgb;
                float3 lightDir = _WorldSpaceLightPos0;
                float NdotL = max(0, dot(normal.xyz, -lightDir) );
                
                //Specular 
				float3 lightReflectDir = reflect(normal.rgb, -_WorldSpaceLightPos0);
				float3 RdotV = max(0, dot( lightReflectDir, i.viewDir ) );
				float3 specularity = pow(RdotV, _SpecularGloss/4) * _SpecularPower * _SpecularColor.rgb;
				
                //Combine
                float3 litColor = saturate( (NdotL  * _Color) + specularity ); 

				litColor *= _LightCol * _LightIntensity;

                col.rgb = litColor;

                return col;
            }
            ENDCG
        }
    }
}
