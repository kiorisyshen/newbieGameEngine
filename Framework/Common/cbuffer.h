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

namespace newbieGE
{
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
    Vector4f m_lightPosition;                  // 16 bytes
    Vector4f m_lightColor;                     // 16 bytes
    Vector4f m_lightDirection;                 // 16 bytes
    float    m_lightDistAttenCurveParams[5];   // 20 bytes
    float    m_lightAngleAttenCurveParams[5];  // 20 bytes
    Vector2f m_lightSize;                      // 8 bytes
    int32_t  m_lightDistAttenCurveType;        // 4 bytes
    int32_t  m_lightAngleAttenCurveType;       // 4 bytes
    float    m_lightIntensity;                 // 4 bytes
    int32_t  m_lightType;                      // 4 bytes
    // Above is 112 bytes

    // Add 16 bytes to align to 128 bytes (Metal required)
    float _alignTmp[4];  // 16 bytes
};

unistruct LightInfo REGISTER(b12)
{
    struct Light lights[MAX_LIGHTS];
};

// Align for metal
struct PerFrameConstants REGISTER(b10) {
    Matrix4X4f m_worldMatrix;       // 64 bytes
    Matrix4X4f m_viewMatrix;        // 64 bytes
    Matrix4X4f m_projectionMatrix;  // 64 bytes
    Vector4f   m_ambientColor;      // 16 bytes
    int32_t    m_numLights;         // 4 bytes
};

struct PerBatchConstants REGISTER(b11) {
    Matrix4X4f m_objectLocalMatrix;  // 64 bytes
    Vector4f   m_diffuseColor;       // 16 bytes
    Vector4f   m_specularColor;      // 16 bytes
    float      m_specularPower;      // 4 bytes
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
