#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct PerFrameConstants
{
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4   lightPosition;
    float4   lightColor;
};

struct Debug_PerBatchConstants
{
    float4x4 modelMatrix;
};

struct debug_vert_out
{
    float4 position [[position]];
    float4 color;
    float size [[point_size]];
};

struct debug_vert_in
{
    float4 position;
    float4 color;
};

vertex debug_vert_out debug_vert_main(uint vID [[vertex_id]],
                                      constant debug_vert_in *in [[buffer(7)]],
                                      constant Debug_PerBatchConstants& pbc[[buffer(8)]],
                                      constant PerFrameConstants& v_43 [[buffer(10)]])
{
    debug_vert_out out;
    
    float4x4 transM = v_43.worldMatrix * pbc.modelMatrix;
    out.position = transM * in[vID].position;
    out.position = v_43.viewMatrix * out.position;
    out.position = v_43.projectionMatrix * out.position;
    
    out.color = in[vID].color;
    out.size = 5;

    return out;
}

fragment float4 debug_frag_main(debug_vert_out in [[stage_in]])
{
    return in.color;
}
