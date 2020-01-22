Shader "ImageEffect/AlphaBloom"
{
    Properties
    {
        [HideInInspector]
        _MainTex("Texture", 2D) = "white" {}

        [KeywordEnum(ADDITIVE, SCREEN, DEBUG)]
        _COMPOSITE_TYPE("Composite Type", Float) = 0

        _Parameter("(Threhold, Intensity, SamplingFrequency, -)", Vector) = (0.8, 1.0, 1.0, 0.0)
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        #include "Assets/Packages/Shaders/ImageFilters.cginc"

        sampler2D _MainTex;
        float4    _MainTex_ST;
        float4    _MainTex_TexelSize;
        float4    _Parameter;

        #define BRIGHTNESS_THRESHOLD _Parameter.x
        #define INTENSITY            _Parameter.y
        #define SAMPLING_FREQUENCY   _Parameter.z

        ENDCG

        // STEP:1
        // Get resized brightness image.

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag

            fixed4 frag(v2f_img input) : SV_Target
            {
                float4 color = tex2D(_MainTex, input.uv);
                return max(color * color.a - BRIGHTNESS_THRESHOLD, 0) * INTENSITY;
            }

            ENDCG
        }

        // STEP:2, 3
        // Get blurred brightness image.

        CGINCLUDE

        struct v2f_gaussian
        {
            float4 pos    : SV_POSITION;
            half2  uv     : TEXCOORD0;
            half2  offset : TEXCOORD1;
        };

        float4 frag_gaussian (v2f_gaussian input) : SV_Target
        {
            return GaussianFilter(_MainTex, _MainTex_ST, input.uv, input.offset);
        }

        ENDCG

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag_gaussian

            v2f_gaussian vert(appdata_img v)
            {
                v2f_gaussian o;

                o.pos    = UnityObjectToClipPos (v.vertex);
                o.uv     = v.texcoord;
                o.offset = _MainTex_TexelSize.xy * float2(1, 0) * SAMPLING_FREQUENCY;

                return o;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag_gaussian

            v2f_gaussian vert(appdata_img v)
            {
                v2f_gaussian o;

                o.pos    = UnityObjectToClipPos (v.vertex);
                o.uv     = v.texcoord;
                o.offset = _MainTex_TexelSize.xy * float2(0, 1) * SAMPLING_FREQUENCY;

                return o;
            }

            ENDCG
        }

        // STEP:4
        // Composite to original.

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag
            #pragma multi_compile _COMPOSITE_TYPE_ADDITIVE _COMPOSITE_TYPE_SCREEN _COMPOSITE_TYPE_DEBUG

            sampler2D _CompositeTex;

            fixed4 frag(v2f_img input) : SV_Target
            {
                float4 mainColor      = tex2D(_MainTex,      input.uv);
                float4 compositeColor = tex2D(_CompositeTex, input.uv);

                #if defined(_COMPOSITE_TYPE_SCREEN)

                return saturate(mainColor + compositeColor - saturate(mainColor * compositeColor));

                #elif defined(_COMPOSITE_TYPE_ADDITIVE)

                return saturate(mainColor + compositeColor);

                #else

                return compositeColor;

                #endif
            }

            ENDCG
        }
    }
}