Shader "Q/ScrollTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed("Scroll Speed",Range(0,50)) = 2
        _Cutout("Cutout",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags
        {
//            "Queue"="AlphaTest"
//            "Queue" = "Transparent"
            "Queue" = "Geometry"
            
//            "IgnoreProjector"="True"
        //    "RenderType"="TransparentCutout"
            "RenderType" = "Opaque"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
       
        Pass
        {
            AlphaToMask On
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Speed;
            float _Cutout;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.uv.x = (o.uv.x + (_Time.x * _Speed)) % 1;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv );

                
                return col;
            }
            ENDCG
        }
    }
}
