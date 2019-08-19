#ifndef __STDCBUFFER_H__
#define __STDCBUFFER_H__

#define MAX_LIGHTS 100

#include "config.h"

#ifdef __cplusplus
#include "SceneObjectLight.hpp"
#include "crossguid/Guid.hpp"
#include "geommath.hpp"
using namespace newbieGE;
#define SEMANTIC(a)
#define REGISTER(x)
#define unistruct struct
#define SamplerState void

namespace newbieGE {
enum LightType {
    Omni     = 0,
    Spot     = 1,
    Infinity = 2,
    Area     = 3,
};
#else
#define SEMANTIC(a) : a
#define REGISTER(x) : register(x)
#define unistruct cbuffer
#define int32_t int
#define Guid int4
#define Vector2f float2
#define Vector3f float3
#define Vector4f float4
#define Matrix2X2f row_major float2x2
#define Matrix3X3f row_major float3x3
#define Matrix4X4f row_major float4x4
#define LightType int
#define AttenCurveType int
#endif

// 128 bytes
struct Light {
    Matrix4X4f lightVP;                   // 64 bytes
    Vector4f lightPosition;               // 16 bytes
    Vector4f lightColor;                  // 16 bytes
    Vector4f lightDirection;              // 16 bytes
    float lightDistAttenCurveParams[6];   // 32 bytes
    float lightAngleAttenCurveParams[6];  // 32 bytes
    Vector2f lightSize;                   // 8 bytes
    int32_t lightDistAttenCurveType;      // 4 bytes
    int32_t lightAngleAttenCurveType;     // 4 bytes
    float lightIntensity;                 // 4 bytes
    int32_t lightType;                    // 4 bytes
    int32_t lightCastShadow;              // 4 bytes
    int32_t lightShadowMapIndex;          // 4 bytes
    // Above is 208 bytes

    // Fill bytes to align to 256 bytes (Metal required)
    float padding[16];  // 48 bytes
};

unistruct LightInfo REGISTER(b12) {
    struct Light lights[MAX_LIGHTS];
};

struct frame_textures {
    int32_t shadowMap;
    std::vector<int32_t> shadowMapLayerIndex;
};

// Align for metal
struct PerFrameConstants REGISTER(b10) {
    Matrix4X4f worldMatrix;       // 64 bytes
    Matrix4X4f viewMatrix;        // 64 bytes
    Matrix4X4f projectionMatrix;  // 64 bytes
    Vector4f ambientColor;        // 16 bytes
    int32_t numLights;            // 4 bytes
};

struct PerBatchConstants REGISTER(b11) {
    Matrix4X4f objectLocalMatrix;  // 64 bytes
    Vector4f diffuseColor;         // 16 bytes
    Vector4f specularColor;        // 16 bytes
    float specularPower;           // 4 bytes
};

#ifdef DEBUG
struct DEBUG_PerBatchConstants REGISTER(b8) {
    Matrix4X4f modelMatrix;
};

struct DEBUG_PointParam REGISTER(b7) {
    Vector4f pos;
    Vector4f color;
};

struct DEBUG_LineParam REGISTER(b7) {
    DEBUG_PointParam from;
    DEBUG_PointParam to;
};

struct DEBUG_TriangleParam REGISTER(b7) {
    DEBUG_PointParam v0;
    DEBUG_PointParam v1;
    DEBUG_PointParam v2;
};

#ifdef __cplusplus
const size_t kSizeDebugMaxAtomBuffer = ALIGN(sizeof(DEBUG_TriangleParam), 256);  // CB size is required to be 256-byte aligned.
#endif
#endif  // DEBUG

#ifdef __cplusplus
const size_t kSizePerFrameConstantBuffer = ALIGN(sizeof(PerFrameConstants), 256);  // CB size is required to be 256-byte aligned.
const size_t kSizePerBatchConstantBuffer = ALIGN(sizeof(PerBatchConstants), 256);  // CB size is required to be 256-byte aligned.
const size_t kSizeLightInfo              = ALIGN(sizeof(LightInfo), 256);          // CB size is required to be 256-byte aligned.
#endif

#ifdef __cplusplus
}  // namespace newbieGE
#endif

#endif  // !__STDCBUFFER_H__
