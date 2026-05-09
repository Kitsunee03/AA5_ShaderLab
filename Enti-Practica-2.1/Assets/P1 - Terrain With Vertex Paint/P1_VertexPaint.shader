Shader "Custom/P1_VertexPaint"
{
    Properties
    {
        [Header(Surface Inputs)]
        _UVScale ("UV Scale", Float) = 1
        _VerticalDisplacement ("Vertical Displacement", Range(0,5)) = 0

        [Header(Blending)]
        _BlendDistance ("Blend Distance", Range(0,5)) = 0.25
        [NoScaleOffset]
        _NoiseTexture ("NoiseTexture", 2D) = "white" {}

        [Header(A B)]
        _IndexA ("Index A", Range(0,1)) = 0
        _IndexB ("Index B", Range(0,1)) = 1
        [NoScaleOffset]
        _AlbedoArray ("Albedo Array", 2DArray) = "" {}
        [NoScaleOffset]
        _NormalArray ("Normal Array", 2DArray) = "" {}
        [NoScaleOffset]
        _MAOHSArray ("MAOHS Array", 2DArray) = "" {}

        [Header(Snow)]
        _SnowMetallic ("Snow Metallic", Range(0,1)) = 0
        _SnowSmoothness ("Snow Smoothness", Range(0,1)) = 0.5
        _SnowAO ("Snow AO", Range(0,1)) = 1

        [HideInInspector]
        _Snow ("Snow", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Texture arrays require shader model 3.5
        #pragma target 3.5

        #include "UnityCG.cginc"

        UNITY_DECLARE_TEX2DARRAY(_AlbedoArray);
        UNITY_DECLARE_TEX2DARRAY(_NormalArray);
        UNITY_DECLARE_TEX2DARRAY(_MAOHSArray);
        sampler2D _NoiseTexture;

        struct Input
        {
            float2 uv_AlbedoArray;
            fixed4 color : COLOR;
        };

        float _UVScale;
        float _BlendDistance;
        float _IndexA;
        float _IndexB;
        float _VerticalDisplacement;
        fixed4 _Snow;
        half _SnowMetallic;
        half _SnowSmoothness;
        half _SnowAO;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert (inout appdata_full v)
        {
            float displacement = v.color.b * _VerticalDisplacement;
            v.vertex.xyz += v.normal * displacement;
        }

        struct TextureSet
        {
            float3 albedo;
            float3 normalTS;
            float4 maohs;
        };

        TextureSet SampleSet(float2 uv, float index)
        {
            TextureSet set;
            float3 uvw = float3(uv, index);
            float4 albedoSample = UNITY_SAMPLE_TEX2DARRAY(_AlbedoArray, uvw);
            float4 normalSample = UNITY_SAMPLE_TEX2DARRAY(_NormalArray, uvw);
            float4 maohsSample = UNITY_SAMPLE_TEX2DARRAY(_MAOHSArray, uvw);

            set.albedo = albedoSample.rgb;
            set.normalTS = UnpackNormal(normalSample);
            set.maohs = maohsSample;
            return set;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_AlbedoArray * _UVScale;
            float noiseR = tex2D(_NoiseTexture, uv).r;
            float blendDenom = max(_BlendDistance, 1e-5);

            float maskAB = saturate((IN.color.r + noiseR) / blendDenom);
            float maskSnow = saturate((IN.color.g + noiseR - 0.5) / blendDenom);

            TextureSet setA = SampleSet(uv, _IndexA);
            TextureSet setB = SampleSet(uv, _IndexB);

            float3 baseAlbedo = lerp(setA.albedo, setB.albedo, maskAB);
            float3 baseNormal = normalize(lerp(setA.normalTS, setB.normalTS, maskAB));
            float4 baseMAOHS = lerp(setA.maohs, setB.maohs, maskAB);

            o.Albedo = lerp(baseAlbedo, _Snow.rgb, maskSnow);
            o.Normal = baseNormal;
            o.Metallic = lerp(baseMAOHS.r, _SnowMetallic, maskSnow);
            o.Occlusion = lerp(baseMAOHS.g, _SnowAO, maskSnow);
            o.Smoothness = lerp(baseMAOHS.a, _SnowSmoothness, maskSnow);
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
