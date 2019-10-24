#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

// Control Point struct
struct ControlPoint {
    float4 position [[attribute(0)]];
};

// Patch struct
struct PatchIn {
    patch_control_point<ControlPoint> control_points;
};

// 4 control pts
struct AllControlPts {
    ControlPoint control_points[4];
};

// Vertex-to-Fragment struct
struct FunctionOutIn {
    float4 position [[position]];
    half4 color [[flat]];
};

struct Terrain_vert_out {
    float4 normal_world [[user(locn0)]];
    float4 v_world [[user(locn1)]];
    float2 uv [[user(locn2)]];
    float3 TBN_0 [[user(locn3)]];
    float3 TBN_1 [[user(locn4)]];
    float3 TBN_2 [[user(locn5)]];
    // float3 v_tangent [[user(locn8)]];
    // float3 camPos_tangent [[user(locn9)]];
    float4 gl_Position [[position]];
};

struct PerFrameConstants {
    float4x4 worldMatrix;  // 64 bytes
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 camPos;
    int numLights;
};

bool offscreen(thread const float4 &vertex0) {
    if (vertex0.z < (-0.5)) {
        return true;
    }
    bool _94 = any(vertex0.xy < float2(-1.7));
    bool _104;
    if (!_94) {
        _104 = any(vertex0.xy > float2(1.7));
    } else {
        _104 = _94;
    }
    return _104;
}

float2 screen_space(thread const float4 &vertex0) {
    return (clamp(vertex0.xy, float2(-1.3), float2(1.3)) + float2(1.0)) * float2(480.0, 270.0);
}

float4 project(thread const float4 &vertex0, constant PerFrameConstants &v_43) {
    float4 result = (v_43.projectionMatrix * v_43.viewMatrix * v_43.worldMatrix) * vertex0;
    result /= float4(result.w);
    return result;
}

float tesselLevel(thread const float2 &v0, thread const float2 &v1) {
    return clamp(distance(v0, v1) / 2.0, 1.0, 64.0);
}

kernel void terrainFillFactors_comp_main(device MTLQuadTessellationFactorsHalf *factors [[buffer(0)]],
                                         constant AllControlPts &pts [[buffer(1)]],
                                         constant PerFrameConstants &pfc [[buffer(10)]],
                                         uint pid [[thread_position_in_grid]]) {
    float4 param  = pts.control_points[0].position;
    float4 v0     = project(param, pfc);
    float4 param1 = pts.control_points[1].position;
    float4 v1     = project(param1, pfc);
    float4 param2 = pts.control_points[2].position;
    float4 v2     = project(param2, pfc);
    float4 param3 = pts.control_points[3].position;
    float4 v3     = project(param3, pfc);

    if (all(bool4(offscreen(v0), offscreen(v1), offscreen(v2), offscreen(v3)))) {
        factors[pid].edgeTessellationFactor[0]   = 0.0;
        factors[pid].edgeTessellationFactor[1]   = 0.0;
        factors[pid].edgeTessellationFactor[2]   = 0.0;
        factors[pid].edgeTessellationFactor[3]   = 0.0;
        factors[pid].insideTessellationFactor[0] = 0.0;
        factors[pid].insideTessellationFactor[1] = 0.0;
    } else {
        float2 ss0 = screen_space(v0);
        float2 ss1 = screen_space(v1);
        float2 ss2 = screen_space(v2);
        float2 ss3 = screen_space(v3);
        float e0   = tesselLevel(ss1, ss2);
        float e1   = tesselLevel(ss0, ss1);
        float e2   = tesselLevel(ss3, ss0);
        float e3   = tesselLevel(ss2, ss3);

        factors[pid].edgeTessellationFactor[0]   = e0;
        factors[pid].edgeTessellationFactor[1]   = e1;
        factors[pid].edgeTessellationFactor[2]   = e2;
        factors[pid].edgeTessellationFactor[3]   = e3;
        factors[pid].insideTessellationFactor[0] = mix(e1, e2, 0.5);
        factors[pid].insideTessellationFactor[1] = mix(e0, e3, 0.5);
    }
}

[[patch(quad, 4)]] vertex Terrain_vert_out terrain_vert_main(PatchIn patchIn [[stage_in]],
                                                             float2 patch_coord [[position_in_patch]],
                                                             constant PerFrameConstants &pfc [[buffer(10)]]) {
    Terrain_vert_out out;

    // Parameter coordinates
    float u = patch_coord.x;
    float v = patch_coord.y;

    float4 a = mix(patchIn.control_points[0].position, patchIn.control_points[1].position, u);
    float4 b = mix(patchIn.control_points[3].position, patchIn.control_points[2].position, u);

    out.uv           = patch_coord.xy;
    out.v_world      = mix(a, b, v);
    out.normal_world = float4(0.0, 0.0, 1.0, 0.0);
    out.gl_Position  = pfc.projectionMatrix * pfc.viewMatrix * out.v_world;

    float3 tangent = float3(1.0f, 0.0f, 0.0f);
    //float3 bitangent = float3(0.0f, 1.0f, 0.0f);

    out.TBN_0 = tangent;
    out.TBN_1 = cross(out.normal_world.xyz, tangent);
    out.TBN_2 = out.normal_world.xyz;

    return out;
}

// Common fragment function
fragment float4 terrain_frag_main(Terrain_vert_out fragmentIn [[stage_in]]) {
    return float4(1.0, 1.0, 1.0, 1.0);
}
