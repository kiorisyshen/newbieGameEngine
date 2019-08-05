#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct ShadowOutput {
    float4 position [[position]];
};

struct ShadowInput {
    float3 inputPosition [[attribute(0)]];
};

struct ShadowMapConstants {
    float4x4 shadowMatrix;
};

struct PerBatchConstants {
    float4x4 objectLocalMatrix;  // 64 bytes
    float4 diffuseColor;         // 16 bytes
    float4 specularColor;        // 16 bytes
    float specularPower;         // 4 bytes
};

vertex ShadowOutput shadow_vert_main(const device ShadowInput &in [[buffer(0)]], constant PerBatchConstants &pbc [[buffer(11)]], constant ShadowMapConstants &smc [[buffer(14)]]) {
    ShadowOutput out;
    float4 v     = float4(in.inputPosition, 1.0);
    v            = pbc.objectLocalMatrix * v;
    out.position = smc.shadowMatrix * v;
    return out;
}
