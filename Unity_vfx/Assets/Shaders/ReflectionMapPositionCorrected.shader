Shader "Q/ReflectionMapPositionCorrected"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",COLOR) = (1,1,1,1)

        _ReflBox0Size("Refl Box 0 size xyz", Vector) = (1,1,1,0)
        _ReflBox0Pos("Refl Box 0 pos xyz", Vector) = (0,0,0,0)
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 vertexWS : TEXCOORD1;
                float3 reflectedViewDirWS : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;

            float3 _ReflBox0Size;
            float3 _ReflBox0Pos;

            float3 BoxProjection(float3 direction, float3 position, float3 cubemapPos, float3 boxMin, float3 boxMax)
            {
                float3 FirstPlaneIntersect = (boxMax - position) / direction;
                float3 SecondPlaneIntersect = (boxMin - position) / direction;
                float3 FurthestPlane = max(FirstPlaneIntersect, SecondPlaneIntersect);

                float distance = min(min(FurthestPlane.x, FurthestPlane.y), FurthestPlane.z);
                float3 intersectPos = position + direction * distance;
                intersectPos -= cubemapPos;
                return intersectPos;

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 normal_worldSpace = UnityObjectToWorldNormal(v.normal);

                o.vertexWS = mul( unity_ObjectToWorld, v.vertex);
                float3 viewDirWS = o.vertexWS - _WorldSpaceCameraPos;
                o.reflectedViewDirWS = reflect( viewDirWS, normal_worldSpace);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                float3 reflectedView =  BoxProjection(i.reflectedViewDirWS, i.vertexWS, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);


                float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectedView);
               // float3 envSampleLDR = DecodeHDR(envSample, unity_SpecCube0_HDR);
                col.rgb *= envSample;

                col *= _Color;

                return col;
            }
            ENDCG
        }
    }
}
