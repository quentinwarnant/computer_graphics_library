Shader "Q/Raymarching_Sphere"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 vertex_worldSpace : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex_worldSpace = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            #define STEPS = 64
            #define STEP_SIZE = 0.01

            bool SphereHit(float3 position, float3 center, float radius)
            {
                return distance(position, center) < radius;
            }

            float RaymarchingHit(float3 position, float3 direction)
            {
                for(int i = 0; i < 64; i++)
                {
                    if( SphereHit(position, float3(0,0,0), 0.5) )
                    {
                        return position;
                    }

                    position += direction * 0.01;
                }

                //no hits
                return 0.0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.vertex_worldSpace - _WorldSpaceCameraPos);
                float depth = RaymarchingHit(i.vertex_worldSpace, viewDir);

                fixed4 col;
                col = fixed4(1,0,0,smoothstep(0,0.001, depth));

                return col;
            }
            ENDCG
        }
    }
}
