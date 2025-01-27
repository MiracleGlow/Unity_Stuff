Shader "Toon/Hair"
{
    Properties
    {
        _Color("Color (RGBA)", Color) = (1,1,1,1)
        _MainTex("Main Texture", 2D) = "white" {}
        _SphereAddTex("Sphere Texture", 2D) = "black" {}
        _Shininess("Shininess", Range(0.0, 5.0)) = 1.0

        _ShadowThreshold("Shadow Threshold", Range(0.0, 1.0)) = 0.5
        _ShadowColor("Shadow Color (RGBA)", Color) = (0,0,0,0.5)
        _ShadowSharpness("Shadow Sharpness", Range(0.0, 100.0)) = 100
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Transparent" }
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
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_SphereAddTex);
            SAMPLER(sampler_SphereAddTex);

            float4 _Color;
            float _Shininess;
            float _ShadowThreshold;
            float4 _ShadowColor;
            float _ShadowSharpness;

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                // Texture sampling
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                // Calculate view-normal interaction
                float3 worldNormal = normalize(i.worldNormal);
                float3 viewDir = normalize(GetCameraPositionWS() - TransformObjectToWorld(i.positionHCS.xyz));
                float3 reflected = reflect(-viewDir, worldNormal);
                float2 sphereUV = reflected.xy * 0.5 + 0.5;

                float4 sphereColor = SAMPLE_TEXTURE2D(_SphereAddTex, sampler_SphereAddTex, sphereUV);

                // Shadow Calculation
                float lightStrength = saturate(dot(worldNormal, GetMainLightDirection()));
                float shadowFactor = saturate((lightStrength - _ShadowThreshold) * _ShadowSharpness);
                float4 shadowColor = lerp(_ShadowColor, float4(1, 1, 1, 1), shadowFactor);

                // Combine colors
                float4 finalColor = baseColor * (1 - shadowFactor) + sphereColor * shadowFactor;
                finalColor *= shadowColor;
                finalColor.a = baseColor.a;

                return finalColor;
            }
            ENDHLSL
        }
    }

    FallBack "Unlit/Transparent"
}
