Shader "Q/Refraction/RefractedGlass"
{
    Properties
    {
        _RefractionIndex ("Index of Refraction", float) = 0.1
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
                float2 uv : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float3 viewDir_WS : TEXCOORD1;
                //float2 uv : TEXCOORD0;
            };

            sampler2D _NormalAndDepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir_WS = worldPos - _WorldSpaceCameraPos;

                //o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex);
    

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                fixed4 dataTex = tex2D(_NormalAndDepthTex, UNITY_PROJ_COORD(i.scrPos)); 
                col.xyz = dataTex.wwww;

                // TODO: use viewDIR to sample normal and depth Tex
                //col.xyz = normalize(i.viewDir_WS);

                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
