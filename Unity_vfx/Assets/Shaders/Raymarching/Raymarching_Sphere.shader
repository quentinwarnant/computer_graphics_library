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

            bool SphereHit(float3 position, float3 center, float radius)
            {
                return distance(position, center) < radius;
            }

            bool BoxHit(float3 position, float3 center, float3 size)
            {
                float3 halfSize = size / 2;
                if( (position.x >=  center.x - halfSize.x )   && (position.x <= center.x + halfSize.x)
                && (position.y >=  center.y - halfSize.y )   && (position.y <= center.y + halfSize.y)
                && (position.z >=  center.z - halfSize.z )   && (position.z <= center.z + halfSize.z)
                )
                {
                    return true;
                }
                return false;
            }

            #define STEPS 128
            #define STEP_SIZE 0.01

            float3 RaymarchingHit(float3 position, float3 center, float3 direction)
            {

                for(int i = 0; i < STEPS; i++)
                {
                    if( SphereHit(position, center, 0.34) )
                    {
                        return (position);
                    }
                    else if (BoxHit(position, center, float3(0.3, 1, 0.3) ) )
                    {
                        return (position);
                    }

                    position += direction * STEP_SIZE;
                }

                //no hits
                return float3(0,0,0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 center = float3(0,0,0);
                float3 viewDir = normalize(i.vertex_worldSpace - _WorldSpaceCameraPos);
                float3 depth = RaymarchingHit(i.vertex_worldSpace, center, viewDir);

                fixed4 col = fixed4(1,0,0,0);
                //col = fixed4(depth, depth, depth, depth);//fixed4(1,0,0,smoothstep(0,0.001, depth));
                float depthLength = length(depth);
                if( depthLength > 0 )
                {
                    col.a = 1;
                    float3 normal = normalize(depth- center);
                    float NdotL =  dot(normal, _WorldSpaceLightPos0);
                    float ambient = 0.2;
                    float light = saturate(ambient +  max(0, NdotL));
                    col.rgb = fixed3(1,0,0) * light;
                }

                return col;
            }
            ENDCG
        }
    }
}
