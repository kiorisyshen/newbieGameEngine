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

struct Light {
    float4 lightPosition;                 // 16 bytes
    float4 lightColor;                    // 16 bytes
    float4 lightDirection;                // 16 bytes
    float lightDistAttenCurveParams[5];   // 20 bytes
    float lightAngleAttenCurveParams[5];  // 20 bytes
    float2 lightSize;                     // 8 bytes
    int lightDistAttenCurveType;          // 4 bytes
    int lightAngleAttenCurveType;         // 4 bytes
    float lightIntensity;                 // 4 bytes
    int lightType;                        // 4 bytes
    int lightCastShadow;                  // 4 bytes
    int lightShadowMapIndex;              // 4 bytes
    float4x4 lightVP;                     // 64 bytes
    // Above is 184 bytes

    // Fill bytes to align to 256 bytes (Metal required)
    float padding[18];  // 72 bytes
};

struct LightInfo {
    Light lights[100];
};

struct PerBatchConstants {
    float4x4 objectLocalMatrix;  // 64 bytes
    float4 diffuseColor;         // 16 bytes
    float4 specularColor;        // 16 bytes
    float specularPower;         // 4 bytes
};

vertex ShadowOutput shadow_vert_main(const device ShadowInput &in [[buffer(0)]], constant PerBatchConstants &pbc [[buffer(11)]], constant LightInfo &pfc_light [[buffer(12)]]) {
    ShadowOutput out;
    float4 v     = float4(in.inputPosition, 1.0);
    v            = pbc.objectLocalMatrix * v;
    out.position = pfc_light.lights[0].lightVP * v;
    return out;
}
