Shader "Q/Refraction/RefractedGlass"
{
    Properties
    {
        _RefractionIndex ("Index of Refraction", Range(0,2)) = 1.0
        _Test ("Test Value", Range(0,1)) = 1.0

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


            sampler2D CustomDepthTex_Inv;
            sampler2D CustomDepthTex_Reg;

            //combined
            sampler2D _NormalAndDepthTex;
            

            samplerCUBE _Skybox;

            fixed _RefractionIndex;
            fixed _Test;

            float DistanceAlongNormal(float3 worldPos)
            {
                return 1;
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

                fixed4 normalDepthInv = tex2D(CustomDepthTex_Reg, screenUV);
                fixed4 dataTex = tex2D(_NormalAndDepthTex, screenUV); 
                //fixed4 dataTex = tex2D(_NormalAndDepthTex, UNITY_PROJ_COORD(screenCoord)); 
                //col.xyz = dataTex.wwww;

                float3 worldPos = i.worldPos;
                float3 viewDir = normalize(i.viewDir_WS);
                float3 normal_WS = normalize(i.worldNormal);
                float3 invNormal_WS = -normal_WS;

                //ni = index of refraction in incident medium (exterrior, ie: air)
                //nt = index of refraction in transmitted medium (interrior, ie: glass)
                //Behaviour of a refracted ray according to Snells law: ni * Sin( Angle of incidence) = nt * Sin( Angle ot transmittance)
                // ie, transmitted angle = arcsin( (ni * sin(angle of incidence) / nt );

                float ni = _RefractionIndex;
                float nt = 1.2;

                float3 incidentDir = viewDir;
                //float angleOfIncidence = acos( dot(incidentDir, normal_WS));
                //float angleOfTransmission = arcsin( (ni * sin(angleOfIncidence) / nt);


                // P1 = i.worldPos
                // P2 = P1 + d*T1
                // T1 = first refracted view dir , interpolation between dV (view dir) & dN (inverted normal)
                // d = distance, which is calculated from _NormalAndDepthTex
                
                float3 T1 = refract(incidentDir, lerp( incidentDir, invNormal_WS, _Test ), ni);
                float dv = dataTex.a;
                float dn = DistanceAlongNormal(i.worldPos);


                //float3 P2 = 

                // TODO: use viewDIR to sample normal and depth Tex
                //col.xyz = normalize(i.viewDir_WS);


                col.rgb = texCUBE(_Skybox, T1 );
                //col.rgb = normalDepthInv.aaa;
                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
