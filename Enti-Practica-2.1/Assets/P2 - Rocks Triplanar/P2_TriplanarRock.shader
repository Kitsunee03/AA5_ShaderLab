Shader "Custom/TriplanarRock"
{
    Properties
    {
        [NoScaleOffset] _Albedo          ("Albedo",           2D)    = "white" {}
        [NoScaleOffset] _Normal          ("Normal",           2D)    = "bump"  {}
        [NoScaleOffset] _MAOHS           ("MAOHS",            2D)    = "white" {}
        _NormalIntensity ("Normal Intensity", Float) = 1.0
        _TileSize        ("Tile Size",        Float) = 1.0
        _Blend           ("Blend",            Float) = 4.0
        [Toggle(USE_LOCAL_SPACE)] _UseLocalSpace ("Use Local Space", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma multi_compile _ USE_LOCAL_SPACE
        #pragma target 3.0

        sampler2D _Albedo;
        sampler2D _Normal;
        sampler2D _MAOHS;
        float _NormalIntensity;
        float _TileSize;
        float _Blend;

        struct Input
        {
            float3 worldPos;
            float3 worldNormal;
            INTERNAL_DATA
        };

        // ── Triplanar for color texture / data ──────────────────────
        float4 TriplanarSample(sampler2D tex, float3 pos, float3 normal)
        {
            float3 w = pow(abs(normal), _Blend);
            w /= (w.x + w.y + w.z);

            float4 xProj = tex2D(tex, pos.yz);
            float4 yProj = tex2D(tex, pos.xz);
            float4 zProj = tex2D(tex, pos.xy);

            return xProj * w.x + yProj * w.y + zProj * w.z;
        }

        // ── Triplanar for normal map ─────────────────────────────────────
        float3 TriplanarNormal(sampler2D tex, float3 pos, float3 normal)
        {
            float3 w = pow(abs(normal), _Blend);
            w /= (w.x + w.y + w.z);

            float3 nX = UnpackNormal(tex2D(tex, pos.yz));
            float3 nY = UnpackNormal(tex2D(tex, pos.xz));
            float3 nZ = UnpackNormal(tex2D(tex, pos.xy));

            nX.xy *= _NormalIntensity;
            nY.xy *= _NormalIntensity;
            nZ.xy *= _NormalIntensity;

            return normalize(nX * w.x + nY * w.y + nZ * w.z);
        }

        // ── Surface function ──────────────────────────────────────────────
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 pos;
            float3 nrm;

            #ifdef USE_LOCAL_SPACE
                // extract object scale from the world matrix to ensure consistent tiling even when the object is scaled
                float3 objectScale = float3(
                    length(unity_ObjectToWorld._m00_m10_m20),
                    length(unity_ObjectToWorld._m01_m11_m21),
                    length(unity_ObjectToWorld._m02_m12_m22)
                );
                pos = mul(unity_WorldToObject, float4(IN.worldPos, 1.0)).xyz * objectScale / _TileSize;
                nrm = normalize(mul((float3x3)unity_WorldToObject, WorldNormalVector(IN, float3(0,0,1))));
            #else
                pos = IN.worldPos / _TileSize;
                nrm = WorldNormalVector(IN, float3(0,0,1));
            #endif

            float4 albedo = TriplanarSample(_Albedo, pos, nrm);
            float3 norm   = TriplanarNormal(_Normal, pos, nrm);
            float4 maohs  = TriplanarSample(_MAOHS,  pos, nrm);

            o.Albedo     = albedo.rgb;
            o.Normal     = norm;
            o.Metallic   = maohs.r;  // M  - Metallic
            o.Occlusion  = maohs.g;  // AO - Ambient Occlusion
            o.Smoothness = maohs.a;  // S  - Smoothness
            // H (B channel) = Heightmap, not used in PBR standard shader
        }
        ENDCG
    }

    FallBack "Diffuse"
}