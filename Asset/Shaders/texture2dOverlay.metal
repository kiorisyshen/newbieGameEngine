#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct VertOutput {
    float4 position [[position]];
    float2 uv;
};

struct VertInput {
    float2 inputPosition [[attribute(0)]];  // 8 bytes
    float2 uv [[attribute(1)]];             // 8 bytes
};

vertex VertOutput overlay_vert_main(uint vertexID [[vertex_id]], constant VertInput *in [[buffer(0)]]) {
    VertOutput out;
    out.position = float4(in[vertexID].inputPosition.xy, 0.0, 1.0);
    out.uv       = in[vertexID].uv;
    return out;
}

fragment float4 overlay_frag_main(VertOutput in [[stage_in]], depth2d<float> textureMap [[texture(0)]], sampler samp0 [[sampler(0)]]) {
    float color = textureMap.sample(samp0, in.uv);
    color       = clamp(color, 0.0, 1.0);
    if (color < 0.999) {
        color -= 0.8;
        color = clamp(color, 0.0, 1.0);
        color /= 0.2;
        color = clamp(color, 0.0, 1.0);
    }
    // if (color > 0.99999) {
    //     color = 0.0;
    // }
    return float4(color, color, color, 1.0f);
}
