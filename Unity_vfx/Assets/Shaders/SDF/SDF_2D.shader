Shader "Q/SDF/SDF_2D"
{
    Properties
    {
        _InsideCol("Inside Color",COLOR) = (1,1,1,1)
        _OutsideCol("Outside Color",COLOR) = (0,0,1,1)

        _DistanceLine("Distance Line",Float) = 0.2
        _ThicknessLine("Thickness Line",Float) = 0.02
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
                float4 vertex : SV_POSITION;
                float4 vertex_WorldPos : COLOR0;
                
            };

            float4 _InsideCol;
            float4 _OutsideCol;
            

            float _DistanceLine;
            float _ThicknessLine;


            float scene_circling_cube(float2 position)
            {
                float speed = _Time.x * 7;
                float2 offset = float2(4,0);

                position = SDF_Rotate(position, speed);
                position = SDF_Translate(position, offset);
                position = SDF_Rotate(position, -speed * 2 );
                
                return SDF_Rectangle(position, float2(3.5,1.4));
            }

            float scene(float2 position)
            {
                float2 offset = float2(4,0);

                float speed = _Time.x * 2;

                position = SDF_Rotate(position, speed * 2);

                position = SDF_Translate(position, offset);
                position = SDF_Rotate(position, -speed  * 4 );
                float scale = abs ( ( sin(speed * PI) + 2 ) / 3 ) ;
                //position = SDF_Scale(position, scale);

                float rectangle1 = SDF_Rectangle(position, float2(3.5,1.4)) * scale;
                
                float result = rectangle1;
                return result;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex_WorldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 col;
                float sdfValue =  scene(i.vertex_WorldPos.xz);
                /*
                //Anti-aliased distance computation (eg: font)
                float changeOverHalfDistance = fwidth(sdfValue) * 0.5;
                sdfValue = smoothstep(changeOverHalfDistance, -changeOverHalfDistance,sdfValue);

                col.rgb = lerp(_InsideCol, _OutsideCol, sdfValue ) ;
                col.a = 1;
                */

                col = lerp(_InsideCol, _OutsideCol, step(0,sdfValue));

                float changeOverHalfDistance = fwidth(sdfValue) * 0.5;
//                float majorLineDistance = abs(frac(sdfValue / _DistanceLine + 0.5) - 0.5) * _DistanceLine;
                float majorLineDistance = abs( frac( (sdfValue / _DistanceLine)  + 0.5) - 0.5 )* _DistanceLine ;
                float lines = smoothstep( _ThicknessLine-changeOverHalfDistance, _ThicknessLine + changeOverHalfDistance, majorLineDistance);
                col = col*lines;

                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
