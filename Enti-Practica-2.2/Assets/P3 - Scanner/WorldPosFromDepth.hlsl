#ifndef WORLDPOS_FROM_DEPTH_INCLUDED
#define WORLDPOS_FROM_DEPTH_INCLUDED

void WorldPosFromDepth_float(float2 UV, out float3 WorldPos)
{
    float rawDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV);
    float4 ndc = float4(UV.x * 2.0 - 1.0, UV.y * 2.0 - 1.0,
                        rawDepth * 2.0 - 1.0, 1.0);
    float4 worldH = mul(UNITY_MATRIX_I_VP, ndc);
    WorldPos = worldH.xyz / worldH.w;
}

#endif