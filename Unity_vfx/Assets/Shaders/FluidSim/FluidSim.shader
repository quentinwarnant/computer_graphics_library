Shader "Q/FluidSim"
{
    Properties
    {
//        _MainTex ("Texture", 2D) = "white" {}
        _FluidSimTex("Fluid Sim 3D", 3D) = "white" {}
        _StepSize ("Step Size", float) = 0.01
        _Alpha("Alpha", Range(0.001,0.4)) = 0.02
    }
    SubShader
    {
        Tags {
             "RenderType"="Transparent" 

        }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Maximum amount of raymarching samples
            #define MAX_STEP_COUNT 128
            // Allowed floating point inaccuracy
            #define EPSILON 0.00001f


            sampler3D _FluidSimTex;
            float4 _FluidSimTex_ST;

            float _StepSize;
            float _Alpha;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 vertex_ObjSpace : TEXCOORD0;
                float3 vectorToSurface : TEXCOORD1;
            };

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
//                o.vertex_ObjSpace = ((v.vertex * 0.5) + 0.5);
                o.vertex_ObjSpace = v.vertex;

                float3 worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vectorToSurface = worldVertex - _WorldSpaceCameraPos;


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                //fixed4 col = float4(0,0,0,1);
                //col.rgb = tex3D(_FluidSimTex, i.vertex_ObjSpace.xyz+float3(0.5f, 0.5f, 0.5f));
                //col.rgb = i.vertex_ObjSpace.xyz + .5 ;
                //return col;
                
                

                 // Start raymarching at the front surface of the object
                float3 rayOrigin = i.vertex_ObjSpace;

                // Use vector from camera to object surface to get ray direction
                float3 rayDirection = mul(unity_WorldToObject, float4(normalize(i.vectorToSurface), 1));

                float4 color = float4(0, 0, 0, 0);
                float3 samplePosition = rayOrigin;

                // Raymarch through object space
                for (int i = 0; i < MAX_STEP_COUNT; i++)
                {
                    // Accumulate color only within unit cube bounds
                    if(max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + EPSILON)
                    {
                        float4 sampledColor = abs(tex3D(_FluidSimTex, samplePosition + float3(0.5f, 0.5f, 0.5f)).rrrr);
                        sampledColor.a *= _Alpha;
                        color = BlendUnder(color, sampledColor);
                        samplePosition += rayDirection * _StepSize;
                    }
                }

                color.a = color.r;

                return color;


            }
            ENDCG
        }
    }
}
