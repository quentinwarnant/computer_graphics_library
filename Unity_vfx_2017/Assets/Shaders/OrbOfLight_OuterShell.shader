Shader "Q/OrbOfLight_OuterShell"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorMult("Color",Color) = (1,1,1,1)

        _DistortionTex("Distortion",2D) = "white" {}

        _ExpansionRate("Rate",Range(0.5,20)) = 1
        _ExpansionAmplitude("Amplitude",Range(0.005,1)) = 1

        _ScrollSpeed("ScrollSpeed",float) = 1

        _RimPow("Rim Power", float) = 1
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            
            }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal: NORMAL;
            };

            struct v2f
            {
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;

                UNITY_FOG_COORDS(3)

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;

            float4 _ColorMult;

            float _ScrollSpeed;

            float _RimPow;

            float _ExpansionAmplitude;
            float _ExpansionRate;

            v2f vert (appdata v)
            {
                v2f o;

                float3 worldVertexPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldPos = worldVertexPos;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = -UnityObjectToWorldNormal(v.normal); //cull front
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //Distort uvs
                o.uv = o.uv + ( fixed2(sin(_Time.x), cos(-_Time.x*0.2) ) * _ScrollSpeed);
                o.uv2 = o.uv + ( fixed2(cos(-_Time.x), sin(_Time.x*0.2) ) * _ScrollSpeed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 distortionSample = tex2D(_DistortionTex,i.uv);
                fixed2 modifiedUv = i.uv.xy + fixed2(distortionSample.r,distortionSample.r * 1.2);
                fixed2 modifiedUv2 = i.uv2.xy + fixed2(distortionSample.r,distortionSample.r * 1.2);

                // sample the texture
                fixed4 col = tex2D(_MainTex, modifiedUv);
                col += tex2D(_MainTex, modifiedUv2 );
                col /=2;

                float3 viewDir = normalize( _WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                col.a = pow( saturate(  dot( normalize(viewDir),i.normal) ), _RimPow );

                col *= _ColorMult;

                return col;
            }
            ENDCG
        }
    }
}
