Shader "Q/Refraction/RefractedGlass"
{
    Properties
    {
        _RefractionIndexOutside ("Index of Refraction Outside", Range(.85,1)) = 1.0
        _RefractionIndexInside ("Index of Refraction Inside", Range(.85,1)) = 1.0

        _Skybox("Skybox",Cube) = "defaulttexture" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "UniversalForward" }
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
                float3 normal : NORMAL;
                float3 uv : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD0;
                float3 viewDir_WS : TEXCOORD1;
                float4 scrPos : TEXCOORD2;
                float3 uv : TEXCOORD3;
            };

            sampler2D _NormalAndDepthTex;
            
            fixed _RefractionIndexOutside;
            fixed _RefractionIndexInside;
            samplerCUBE _Skybox;

            float DistanceAlongNormal(float3 worldPos)
            {
                //Constant depth approximation, real value could be precalculated and baked into a "thickness along negative normal" texture,
                //But results are actually pretty decent ! 
                return 4;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldNormal = mul(unity_ObjectToWorld, float4(v.normal.xyz,0));
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.viewDir_WS = worldPos - _WorldSpaceCameraPos;

                o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex);

                o.worldNormal = worldNormal;
                o.worldPos = worldPos;
    

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;

                float4 screenCoord = i.scrPos;
                float2 screenUV = screenCoord.xy / screenCoord.w;

                fixed4 dataTex = tex2D(_NormalAndDepthTex, screenUV); 
                //fixed4 dataTex = tex2D(_NormalAndDepthTex, UNITY_PROJ_COORD(screenCoord)); 
                //col.xyz = dataTex.wwww;

                float3 viewDir = normalize(i.viewDir_WS);
                float3 normal_WS = normalize(i.worldNormal);
                float3 invNormal_WS = -normal_WS;

                //ni = index of refraction in incident medium (exterrior, ie: air)
                //nt = index of refraction in transmitted medium (interrior, ie: glass)
                //Behaviour of a refracted ray according to Snells law: ni * Sin( Angle of incidence) = nt * Sin( Angle ot transmittance)
                // ie, transmitted angle = arcsin( (ni * sin(angle of incidence) / nt );

                float ni = _RefractionIndexOutside;
                float nt = _RefractionIndexInside;

                float3 incidentDir = viewDir;

                float3 P1 = i.worldPos;
                
                float3 T1 = refract(incidentDir, normal_WS, ni);
                float dv = dataTex.a;
                float dn = DistanceAlongNormal(i.worldPos);
                float angleDiff = dot(T1, invNormal_WS) / dot(viewDir, normal_WS);
                float d = ( angleDiff * dv ) + ((1-angleDiff)*dn );

                float3 P2 = P1 + (normalize(T1) * d);
                float4 P2screenPos =  mul(UNITY_MATRIX_VP, float4(P2,1));
                float4 P2screenCoord = UNITY_PROJ_COORD( ComputeScreenPos(P2screenPos) );
                float3 N2 = tex2Dproj(_NormalAndDepthTex, P2screenCoord).rgb;
                float3 T2 = refract(T1, N2, nt);

                col.rgb = texCUBE(_Skybox, T2 );
                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}

/*


for all fragments F (given P1, V~ , and N~1), do
V    T~1 = Refract( V~ , N~1 )
V    dV~ = DistanceFrontFaceToBackFace( F , BackfaceZBuf )
    dN~ = DistanceAlongNormal( P1 )
    d˜ =WeightDistance( −N~1 ·T~1, V~ ·T~1, dV~ , dN~ )
    P˜2 = P1 + d˜T~1
    texfar = ProjectToScreenSpace( P˜2 )
    N~2 ≈ TextureLookup( texfar, BackfaceNormals )
    T~2 ≈ Refract( T~1, N~2 )
    return IndexEnvironmentMap( T~2 )

*/

