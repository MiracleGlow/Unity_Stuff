Shader "Toon/Cutoff"
{
    Properties
    {
        _Color("Color (RGBA)", Color) = (1,1,1,1)
        _MainTex("Texture", 2D) = "white" {}
        _ShadowThreshold("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadowColor("Shadow Color (RGBA)", Color) = (0,0,0,0.5)
        _ShadowSharpness("Shadow Sharpness", Float) = 100
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="TransparentCutout" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _Color;
            float _ShadowThreshold;
            float4 _ShadowColor;
            float _ShadowSharpness;

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                // Shadow Calculation
                half3 mainLightDir = GetMainLightDirection();
                float lightStrength = saturate(dot(mainLightDir, float3(0, 0, 1))); // Assume normal = (0,0,1) for simplicity
                float shadowRate = saturate((lightStrength - _ShadowThreshold) * _ShadowSharpness);

                float4 shadowColor = lerp(_ShadowColor, float4(1, 1, 1, 1), shadowRate);
                return texColor * shadowColor;
            }
            ENDHLSL
        }
    }

    FallBack "Unlit/Transparent Cutout"
}
