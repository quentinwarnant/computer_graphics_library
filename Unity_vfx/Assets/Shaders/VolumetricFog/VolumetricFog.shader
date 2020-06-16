Shader "Q/VolumetricFog"
{
    Properties
    {
        _FogCenter("Fog Center", Vector) = (0,0,0, 0.5)
        _FogColor("Fog Color", COLOR) = (1,1,1,1)
        _InnerRatio("Innter Ratio", Range(0.1,0.9)) = 0.5
        _Density("Density",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        Lighting Off
        ZWrite Off
        ZTest Always
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _FogCenter;
            fixed4 _FogColor;
            float _InnerRatio;
            float _Density;
            sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir_worldspace : TEXCOORD0;
                float4 pos_screenspace : TEXCOORD1;
            };

            float CalculateFogIntensity(float3 sphereCenter, float sphereRadius, float innerRatio, float density, float3 camPos, float3 viewDir, float maxDistance)
            {
                //Calculate ray-sphere intersection (see quadratic equations)
                float3 localCamPos = camPos - sphereCenter;

                //a = D^2
                //b = 2 * Camera * D
                //c = camera^2 - R^2

                //for vec3's Dot product of itself results in square of value
                float a = dot(viewDir, viewDir);
                float b = 2 * dot(viewDir, localCamPos);
                float c = dot(localCamPos, localCamPos) - (sphereRadius * sphereRadius);

                //Find how many (0,1 or 2) intersections
                //Find discriminant
                float discriminant = b * b - (4 * a * c);
                if( discriminant <= 0.0)
                {
                    // no intersections
                    return 0; 
                }

                float distanceSqrt = sqrt(discriminant);
                float distance1 = (max( (-b - distanceSqrt) / 2 * a, 0));
                float distance2 = (max( (-b + distanceSqrt) / 2 * a, 0));

                // clamp distance 2 to not be furhter than far plane
                float maxDepth = min(distance2, maxDistance);
                float raymarch_stepCount = 10; 
                float raymarch_stepSize = (maxDepth - distance1) / raymarch_stepCount;
                float raymarch_stepContribution = density;

                float centerValue = 1 / (1-innerRatio);
                float sampleDist = distance1;

                float clarity = 1;
                for(half i = 0; i < raymarch_stepCount; i++)
                {
                    float3 position = camPos + viewDir * sampleDist;
                    float valueAtSample = saturate( centerValue * (1-length(position)/sphereRadius) );
                    float fogAmount = saturate(valueAtSample * raymarch_stepContribution);
                    clarity *= (1-fogAmount);

                    sampleDist += raymarch_stepSize;
                }

                return (1-clarity); // inverse of clarity = fog
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float4 vertex_worldspace = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir_worldspace = vertex_worldspace - _WorldSpaceCameraPos;
                o.pos_screenspace = ComputeScreenPos(o.vertex);

                //Z & W are near & far plane distances
                float inFront = (o.vertex.z / o.vertex.w) > 0;
                o.vertex.z *= inFront;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(
                        UNITY_SAMPLE_DEPTH( 
                            tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.pos_screenspace))
                        )
                    );
                float3 viewDir = normalize(i.viewDir_worldspace);

                float fog = CalculateFogIntensity(
                    _FogCenter.xyz,
                    _FogCenter.w, //radius
                    _InnerRatio,
                    _Density,
                    _WorldSpaceCameraPos,
                    viewDir,
                    depth
                );

                fixed4 col = float4(_FogColor.rgb, fog);
               
                return col;
            }
            ENDCG
        }
    }
}
