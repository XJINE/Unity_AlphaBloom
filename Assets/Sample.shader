Shader "Unlit/Sample"
{
    Properties
    {
                        _Color   ("Color",   Color) = (0, 0, 0, 0.1)
        [NoScaleOffset] _MainTex ("Texture",    2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // NOTE:
        // This makes the object opaque and the rendering result has a custom alpha.

        Blend One Zero, One One

        Pass
        {
            CGPROGRAM

            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv     : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4    _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 color = tex2D(_MainTex, i.uv) * _Color;
                return color;
            }

            ENDCG
        }
    }
}