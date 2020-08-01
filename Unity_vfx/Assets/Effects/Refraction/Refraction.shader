Shader "Q/Refraction"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        ZWrite On
        ZTest Less
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 lighting : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                float4 inversedPos = v.vertex;

//TODO: FIGURE OUT HOW TO INVERSE THE RENDERING ON THE Z AXIS IN VIEW SPACE
// THEN DEPTH BUFFER WILL BE CORRECT FOR FIRST PASS OF EFFECT!
                float4x4 invMatrix = float4x4(  -1,0,0,0,
                                                0,1,0,0,
                                                0,0,1,0,
                                                0,0,0,1);

                float4x4 inversedZMVP = mul(UNITY_MATRIX_P ,  mul( UNITY_MATRIX_V ,UNITY_MATRIX_M) );
                inversedZMVP = mul( inversedZMVP, invMatrix);
                o.vertex =  mul( inversedZMVP, v.vertex);
  
//                o.vertex =  UnityObjectToClipPos(inversedPos);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 NdotL = max(0,dot( worldNormal, _WorldSpaceLightPos0 ));
				
                o.lighting = (NdotL  * fixed3(1,1,1)); 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col = 0.5;
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
