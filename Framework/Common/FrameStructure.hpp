#pragma once
#include <vector>
#include "Scene.hpp"
#include "cbuffer.h"

namespace newbieGE {
ENUM(DefaultShaderIndex){
    BasicShader     = "BSIC"_i32,
    ShadowMapShader = "SHMP"_i32,
    DebugShader     = "DEBG"_i32,
    Overlay2dShader = "OVLY"_i32,
};

ENUM(RenderPassIndex){
    ForwardPass = "FWPS"_i32,
    ShadowPass  = "SHPS"_i32,
    HUDPass     = "HUDP"_i32,
};

enum ShadowMapType {
    NormalShadowMapType = 0,
    CubeShadowMapType,
    GlobalShadowMapType,
    num_ShadowMapType,
};
struct ShadowMapDescription {
    uint32_t width;
    uint32_t height;
    ShadowMapType type;
};

struct DrawFrameContext : PerFrameConstants, frame_textures {
};

struct DrawBatchConstant : PerBatchConstants {
    uint32_t batchIndex;
    std::shared_ptr<SceneGeometryNode> node;

    virtual ~DrawBatchConstant() = default;
};

#ifdef DEBUG
struct DEBUG_DrawBatch {
    DEBUG_PerBatchConstants pbc;
    std::vector<DEBUG_LineParam> lineParams;
    std::vector<DEBUG_PointParam> pointParams;
    std::vector<DEBUG_TriangleParam> triParams;
};
#endif

struct Frame {
    LightInfo lightInfo;
    DrawFrameContext frameContext;
    std::vector<std::shared_ptr<DrawBatchConstant>> batchContext;
#ifdef DEBUG
    std::vector<DEBUG_DrawBatch> DEBUG_Batches;  // The first batch is static with identity transformation
#endif
};
}  // namespace newbieGE
