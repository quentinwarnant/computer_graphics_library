Shader "Q/Refraction/RefractedGlass"
{
    Properties
    {
        _RefractionIndexOutside ("Index of Refraction Outside", Range(.0,2)) = 1.0
        _RefractionIndexInside ("Index of Refraction Inside", Range(.0,2)) = 1.0

        _Skybox("Skybox",Cube) = "defaulttexture" {}
        _TicknessAlongNormal("TicknessAlongNormal",float) = 4
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
                float4 originWS : TEXCOORD4;
            };

            sampler2D _NormalFrontAndDepthTex;
            sampler2D _DepthNormalTexBack;
            
            fixed _RefractionIndexOutside;
            fixed _RefractionIndexInside;
            samplerCUBE _Skybox;

            float _TicknessAlongNormal;

            float DistanceAlongNormal(float3 worldPos)
            {
                //Constant depth approximation, real value could be precalculated and baked into a "thickness along negative normal" texture,
                //But results are actually pretty decent ! 
                return _TicknessAlongNormal;
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
                o.originWS = mul(unity_ObjectToWorld, float4(0,0,0,1));
    

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;

                float4 screenCoord = i.scrPos;
                float2 screenUV = screenCoord.xy / screenCoord.w;

                fixed4 dataTex = tex2D(_NormalFrontAndDepthTex, screenUV); 

                float3 viewDir = normalize(i.viewDir_WS);
                float3 normal_WS = normalize(i.worldNormal);
                float3 invNormal_WS = -normal_WS;

                //nt = index of refraction in transmitted medium (interrior, ie: glass)
                //ni = index of refraction in incident medium (exterrior, ie: air)
                //Behaviour of a refracted ray according to Snells law: ni * Sin( Angle of incidence) = nt * Sin( Angle ot transmittance)
                // ie, transmitted angle = arcsin( (ni * sin(angle of incidence) / nt );

                float nt = _RefractionIndexInside;
                float ni = _RefractionIndexOutside;

                float3 incidentDir = viewDir;

                float3 P1 = i.worldPos;
                
                float3 T1 = normalize(refract(incidentDir, normal_WS, ni/nt));
                float dv = dataTex.a;
                float dn = DistanceAlongNormal(i.worldPos);
                float incidentAngle = dot(incidentDir, normal_WS);

                float angleDiff = dot(T1, invNormal_WS) / incidentAngle;
                float d = lerp( dv ,dn, angleDiff );

                float3 P2 = P1 + (T1 * d);
                float4 P2screenPos =  mul(UNITY_MATRIX_VP, float4(P2,1));
                float4 P2screenCoord = ComputeScreenPos(P2screenPos);
                float3 N2 = tex2D(_DepthNormalTexBack, P2screenCoord.xy / P2screenCoord.w).rgb;
                N2 = (N2 * 2) -1;



                //To address total internal refraction (TIR), we disallow angles > critical angle (for TIR)


                float3 T2;
                
                if(incidentAngle < 0.1){
                    //N2 = T1 - (dot(incidentDir,T1 ) * incidentDir);
                    T2 = reflect(T1,N2);
                }
                else
                {
                    T2 = refract(T1, N2, nt/ni);
                }
/*
                if( N2.x < 0.01 && N2.y < 0.01 && N2.z < 0.01) //no normal
                {
                    N2 = -normal_WS;
                }
*/
               // N2 = P2 - i.originWS; //TEST - find normal for a sphere (for debugging purposes)


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

