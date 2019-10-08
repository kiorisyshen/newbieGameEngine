#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct PerBatchConstants {
    float4x4 objectLocalMatrix;
};

struct PerFrameConstants {
    float4x4 worldMatrix;       // 64 bytes
    float4x4 viewMatrix;        // 64 bytes
    float4x4 projectionMatrix;  // 64 bytes
    float4 ambientColor;        // 16 bytes
    int numLights;              // 4 bytesd
};

struct pbr_vert_main_out {
    float4 normal [[user(locn0)]];
    float4 normal_world [[user(locn1)]];
    float4 v [[user(locn2)]];
    float4 v_world [[user(locn3)]];
    float2 uv [[user(locn4)]];
    float4 gl_Position [[position]];
};

struct pbr_vert_main_in {
    float3 inputPosition [[attribute(0)]];
    float3 inputNormal [[attribute(1)]];
    float2 inputUV [[attribute(2)]];
};

vertex pbr_vert_main_out pbr_vert_main(pbr_vert_main_in in [[stage_in]], constant PerFrameConstants &pfc [[buffer(10)]], constant PerBatchConstants &pbc [[buffer(11)]]) {
    pbr_vert_main_out out = {};

    float4x4 transM = pfc.worldMatrix * pbc.objectLocalMatrix;
    out.v_world     = transM * float4(in.inputPosition, 1.0f);
    out.v           = pfc.viewMatrix * out.v_world;
    out.gl_Position = pfc.projectionMatrix * out.v;

    out.normal_world = normalize(transM * float4(in.inputNormal, 0.0f));
    out.normal       = normalize(pfc.viewMatrix * out.normal_world);
    out.uv.x         = in.inputUV.x;
    out.uv.y         = 1.0 - in.inputUV.y;
    return out;
}
