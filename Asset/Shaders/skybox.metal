#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct PerFrameConstants {
    float4x4 worldMatrix;       // 64 bytes
    float4x4 viewMatrix;        // 64 bytes
    float4x4 projectionMatrix;  // 64 bytes
    float4 ambientColor;        // 16 bytes
    int numLights;              // 4 bytes
};

struct skybox_vert_out {
    float4 position [[position]];
    float3 direction;
};

struct skybox_vert_in {
    float3 position [[attribute(0)]];
};

vertex skybox_vert_out skybox_vert_main(skybox_vert_in in [[stage_in]],
                                        constant PerFrameConstants &pfc [[buffer(10)]]) {
    skybox_vert_out out;

    out.direction = in.position.xyz;

    float4x4 _matrix = pfc.viewMatrix;
    _matrix[3].x     = 0.0;
    _matrix[3].y     = 0.0;
    _matrix[3].z     = 0.0;

    float4 pos   = pfc.projectionMatrix * (_matrix * float4(in.position, 1.0));
    out.position = pos.xyww;

    return out;
}

fragment float4 skybox_frag_main(skybox_vert_out in [[stage_in]],
                                 texturecube<float> skyboxMap [[texture(10)]],
                                 sampler samp0 [[sampler(0)]]) {
    float4 outputColor = skyboxMap.sample(samp0, in.direction);
    return outputColor;
}
