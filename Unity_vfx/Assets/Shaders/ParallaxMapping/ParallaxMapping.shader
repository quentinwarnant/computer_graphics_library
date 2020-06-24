//Per https://catlikecoding.com/unity/tutorials/rendering/part-20/
Shader "Q/ParallaxMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //[NoScaleOffset] _ParallaxDepthTex("Depth",2D) = "black" {}
        _ParallaxDepthStrength("Depth Strength", Range(-1,1)) = 0
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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir_tangentSpace : TEXCOORD1;
                float3 light : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //sampler2D _ParallaxDepthTex;
            float _ParallaxDepthStrength;

            void Parallax(inout v2f i)
            {
                i.viewDir_tangentSpace = normalize(i.viewDir_tangentSpace);
                float heightSample = 1;//tex2D(_ParallaxDepthTex, i.uv).r;
                float height = heightSample * _ParallaxDepthStrength;
                i.uv += i.viewDir_tangentSpace.xy * height;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 viewDir_objectSpace = v.vertex - mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz,1) ).xyz;

                //TODO: understand this matrix
                float3x3 objectToTangentMatrix = float3x3(
                                                    v.tangent.xyz,
                                                    cross(v.normal, v.tangent.xyz) * v.tangent.w, // why???
                                                    v.normal
                                                    );

                o.viewDir_tangentSpace = mul(objectToTangentMatrix, viewDir_objectSpace);

                float3 lightDir_worldSpace = normalize(  _WorldSpaceLightPos0 - mul(unity_ObjectToWorld, v.vertex).xyz); 
                float3 normal_worldSpace =  normalize( UnityObjectToWorldNormal(v.normal) );

                float NdotL = dot(lightDir_worldSpace, normal_worldSpace);
                o.light = NdotL * float3(0.8,0.8,0.8);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float edgeWidth = 0.05;
                float edgeMask = 0;
                float edgeTop = (i.uv.y + edgeWidth );
                float edgeBottom = (1-i.uv.y + edgeWidth );
                float edgeRight = (i.uv.x + edgeWidth );
                float edgeLeft = (1-i.uv.x + edgeWidth );
                edgeMask += edgeTop - frac(edgeTop);
                edgeMask += edgeBottom - frac(edgeBottom);
                edgeMask += edgeRight - frac(edgeRight);
                edgeMask += edgeLeft - frac(edgeLeft);
                edgeMask = saturate(edgeMask);

                //Apply parallax effect
                Parallax(i);

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= 1-edgeMask;

                col.rgb += edgeMask * i.light;

        

                return col;
            }
            ENDCG
        }
    }
}
