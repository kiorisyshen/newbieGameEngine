#ifndef __STDCBUFFER_H__
#define __STDCBUFFER_H__

#define MAX_LIGHTS 100

#include "config.h"

#ifdef __cplusplus
#include "geommath.hpp"
#include "crossguid/Guid.hpp"
#include "SceneObject.hpp"
using namespace newbieGE;
#define SEMANTIC(a)
#define REGISTER(x)
#define unistruct struct
#define SamplerState void

namespace newbieGE
{
enum LightType
{
    Omni = 0,
    Spot = 1,
    Infinity = 2,
    Area = 3
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

// struct Light{
//     float       lightIntensity;               	// 4 bytes
//     LightType   lightType;                    	// 4 bytes
//     int			lightCastShadow;				// 4 bytes
//     int         lightShadowMapIndex;			// 4 bytes
//     AttenCurveType lightAngleAttenCurveType;  	// 4 bytes
//     AttenCurveType lightDistAttenCurveType; 	// 4 bytes
//     Vector2f    lightSize;               		// 8 bytes
//     Guid        lightGuid;                    	// 16 bytes
//     Vector4f    lightPosition;   				// 16 bytes
//     Vector4f    lightColor;   					// 16 bytes
//     Vector4f    lightDirection;   				// 16 bytes
//     Vector4f    lightDistAttenCurveParams[2]; 	// 32 bytes
//     Vector4f    lightAngleAttenCurveParams[2];	// 32 bytes
//     Matrix4X4f  lightVP;						// 64 bytes
//     Vector4f    padding[2];						// 32 bytes
// };

// unistruct Constants
// {
//     Matrix4X4f       m_modelView;
//     Matrix4X4f       m_modelViewProjection;
//     Vector4f         m_lightPosition;
//     Vector4f         m_lightColor;
//     Vector4f         m_ambientColor;
//     Vector4f         m_lightAttenuation;
// };

struct Light
{
    Vector4f m_lightPosition;
    Vector4f m_lightColor;
};

unistruct LightInfo REGISTER(b12)
{
    struct Light lights[MAX_LIGHTS];
};

struct PerFrameConstants REGISTER(b10)
{
    Matrix4X4f m_worldMatrix;
    Matrix4X4f m_viewMatrix;
    Matrix4X4f m_projectionMatrix;
    Vector4f m_lightPosition;
    Vector4f m_lightColor;
};

struct PerBatchConstants REGISTER(b11)
{
    Matrix4X4f m_objectLocalMatrix;
    Vector4f m_diffuseColor;
    Vector4f m_specularColor;
    // float m_specularPower;
};

#ifdef DEBUG
struct DEBUG_PerBatchConstants REGISTER(b8)
{
    Matrix4X4f modelMatrix;
};

struct DEBUG_PointParam REGISTER(b7)
{
    Vector4f pos;
    Vector4f color;
};

struct DEBUG_LineParam REGISTER(b7)
{
    DEBUG_PointParam from;
    DEBUG_PointParam to;
};

struct DEBUG_TriangleParam REGISTER(b7)
{
    DEBUG_PointParam v0;
    DEBUG_PointParam v1;
    DEBUG_PointParam v2;
};

#ifdef __cplusplus
const size_t kSizeDebugMaxAtomBuffer = ALIGN(sizeof(DEBUG_TriangleParam), 256); // CB size is required to be 256-byte aligned.
#endif
#endif

#ifdef __cplusplus
const size_t kSizePerFrameConstantBuffer = ALIGN(sizeof(PerFrameConstants), 256); // CB size is required to be 256-byte aligned.
const size_t kSizePerBatchConstantBuffer = ALIGN(sizeof(PerBatchConstants), 256); // CB size is required to be 256-byte aligned.
const size_t kSizeLightInfo = ALIGN(sizeof(LightInfo), 256);                      // CB size is required to be 256-byte aligned.
#endif

#ifdef __cplusplus
} // namespace newbieGE
#endif

#endif // !__STDCBUFFER_H__
