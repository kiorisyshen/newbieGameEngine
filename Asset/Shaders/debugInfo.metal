#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct debug_vert_out
{
    float4 position [[position]];
    float4 color;
};

struct debug_vert_in
{
    float4 position;
    float4 color;
};

vertex debug_vert_out debug_vert_main(uint vID [[vertex_id]],
                                      constant debug_vert_in *in [[buffer(7)]])
{
    debug_vert_out out;
    out.position = in[vID].position;
    out.color = in[vID].color;

    return out;
}

fragment float4 debug_frag_main(debug_vert_out in [[stage_in]])
{
    return in.color;
}
