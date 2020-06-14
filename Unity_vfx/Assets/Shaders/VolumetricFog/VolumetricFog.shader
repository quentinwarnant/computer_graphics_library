Shader "Q/VolumetricFog"
{
    Properties
    {
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir_worldspace : TEXCOORD0;
                float4 pos_screenspace : TEXCOORD1;
            };

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
                fixed4 col = float4(1,1,1,1);
                return col;
            }
            ENDCG
        }
    }
}
