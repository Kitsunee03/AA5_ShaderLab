#ifndef WORLDPOS_FROM_DEPTH_INCLUDED
#define WORLDPOS_FROM_DEPTH_INCLUDED

void WorldPosFromDepth_float(float2 UV, out float3 WorldPos, out float SkyboxMask)
{
    float rawDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV);

    // skybox mask: 1.0 if the pixel is skybox, 0.0 otherwise
    #if UNITY_REVERSED_Z
        SkyboxMask = (rawDepth < 0.0001) ? 1.0 : 0.0;
    #else
        SkyboxMask = (rawDepth > 0.9999) ? 1.0 : 0.0;
    #endif

    float4 ndc = float4(
        UV.x * 2.0 - 1.0,
        UV.y * 2.0 - 1.0,
        rawDepth * 2.0 - 1.0,
        1.0
    );

    float4 worldH = mul(UNITY_MATRIX_I_VP, ndc);
    WorldPos = worldH.xyz / worldH.w;
}

#endif