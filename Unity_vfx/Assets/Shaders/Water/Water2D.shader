Shader "Q/Water2D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WaveDepth( "Wave Depth", float) = 0.5
        _DeepWater("Deep Water", COLOR) = (1,1,1,1)
        _ShallowWater("Shallow Water", COLOR) = (1,1,1,1)
        
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float  _WaveDepth;
            float4 _DeepWater;
            float4 _ShallowWater;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 noiseCol = tex2D(_MainTex, float2(i.uv.x /3, i.uv.y + _Time.x * 0.5 ));

                fixed shoreLineCount = 4;
                float distortedUvY = i.uv.y + (noiseCol.r * 0.2) - _Time.x;

                // distortedUV = distortedUV 
                //     + float2(
                //         0,
                //         (sin( (((i.uv.x * (i.uv.y*0.4) ) ) * 25) + _Time.y ) / 20 ) 
                //         + _Time.x * 2
                //     );
                distortedUvY = frac(distortedUvY * shoreLineCount); 
                float waveDepth = 1-_WaveDepth;
                fixed wave = smoothstep(waveDepth, 1, distortedUvY);

                wave = wave - (pow(wave,9)); // Soften shape

                //TODO: use wave to lerp caustic texture on top (use voronoi)

                //Fade based on distance
                wave *= smoothstep(0.2, 0.5,i.uv.y);

//                fixed shoreLine = frac( ( ( i.uv.y + distortion ) * shoreLineCount) );
                fixed4 col = lerp(_DeepWater, _ShallowWater, wave);

                return col;
            }
            ENDCG
        }
    }
}
