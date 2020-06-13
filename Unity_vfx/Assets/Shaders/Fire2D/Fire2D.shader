Shader "Q/Fire2D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #include "Assets/Shaders/CGInclude/SDF_2D.cginc"


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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y;
                // sample the texture
                float2 scrollingUV = i.uv + float2(0, -time* 0.5);
                float2 scrollingUV2 = i.uv + float2(time * 0.5, -time * 0.6);


                fixed texSample = tex2D(_MainTex, scrollingUV).g;
                fixed texSample2 = tex2D(_MainTex, scrollingUV2).r;
                texSample = (texSample + texSample2) /2;

                fixed gradient = (1-i.uv.y) * 1.1;

                float step1 = AA_step( texSample, gradient);
                float step2 = AA_step( texSample, gradient-0.2);
                float step3 = AA_step( texSample, gradient-0.4);
                float mask = saturate(step1 + step2 + step3);
                mask -= texSample / 1.9;

                fixed4 red = fixed4(1,0,0,1);
                fixed4 yellow = fixed4(0.9,0.9,0,1);
                fixed4 orange = fixed4(1,0.5,0,1);

                float stepOneMinusTwo = step1 - step2; 
                float stepTwoMinusThree = step2 - step3; 

                fixed4 intermidiateCol = lerp( yellow, red, stepOneMinusTwo);
                
                fixed4 col;
                col = lerp(intermidiateCol, orange, stepTwoMinusThree) * mask;

                return col;
            }
            ENDCG
        }
    }
}
