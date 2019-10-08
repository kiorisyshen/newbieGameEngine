#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct ShadowOutput {
    float4 position [[position]];
    float4 v;
};

struct ShadowCubeOutput {
    float4 position [[position]];
    float4 v;
    uint face [[render_target_array_index]];
};

struct ShadowInput {
    float3 inputPosition [[attribute(0)]];
    float3 inputNormal [[attribute(1)]];
    float2 inputUV [[attribute(2)]];
};

struct CameraVP {
    float4x4 shadowMatrix;
};

struct CameraVPCube {
    float4x4 VPs[6];
};

struct PerFrameConstants {
    float4x4 worldMatrix;       // 64 bytes
    float4x4 viewMatrix;        // 64 bytes
    float4x4 projectionMatrix;  // 64 bytes
    float4 ambientColor;        // 16 bytes
    int numLights;              // 4 bytes
};

struct PerBatchConstants {
    float4x4 objectLocalMatrix;  // 64 bytes
};

vertex ShadowOutput shadow2D_vert_main(ShadowInput in [[stage_in]],
                                       constant PerFrameConstants &pfc [[buffer(10)]],
                                       constant PerBatchConstants &pbc [[buffer(11)]],
                                       constant CameraVP &smc [[buffer(14)]]) {
    ShadowOutput out;

    float4x4 transM = pfc.worldMatrix * pbc.objectLocalMatrix;
    float4 v_world  = transM * float4(in.inputPosition, 1.0);
    out.v           = pfc.viewMatrix * v_world;

    out.position   = smc.shadowMatrix * v_world;
    out.position.y = -out.position.y;

    return out;
}

fragment float4 shadow2D_frag_main(ShadowOutput in [[stage_in]]) {
    return float4(in.position.z, in.position.z, in.position.z, 1.0);
}

vertex ShadowCubeOutput shadowCube_vert_main(ShadowInput in [[stage_in]],
                                             const uint instanceId [[instance_id]],
                                             constant PerFrameConstants &pfc [[buffer(10)]],
                                             constant PerBatchConstants &pbc [[buffer(11)]],
                                             constant CameraVPCube &smc [[buffer(15)]]) {
    ShadowCubeOutput out;

    out.face = instanceId;

    float4x4 transM = pfc.worldMatrix * pbc.objectLocalMatrix;
    float4 v_world  = transM * float4(in.inputPosition, 1.0);
    out.v           = pfc.viewMatrix * v_world;

    out.position = smc.VPs[out.face] * v_world;

    return out;
}

fragment float4 shadowCube_frag_main(ShadowCubeOutput in [[stage_in]]) {
    return float4(in.position.z, in.position.z, in.position.z, 1.0);
}
