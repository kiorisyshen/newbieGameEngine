#pragma once
#include <vector>
#include "Scene.hpp"
#include "cbuffer.h"

namespace newbieGE
{
struct DrawFrameContext : public PerFrameConstants {
};

struct DrawBatchConstant : public PerBatchConstants {
    uint32_t                           batchIndex;
    std::shared_ptr<SceneGeometryNode> node;

    virtual ~DrawBatchConstant() = default;
};

#ifdef DEBUG
struct DEBUG_DrawBatch {
    DEBUG_PerBatchConstants          pbc;
    std::vector<DEBUG_LineParam>     lineParams;
    std::vector<DEBUG_PointParam>    pointParams;
    std::vector<DEBUG_TriangleParam> triParams;
};
#endif

struct Frame {
    LightInfo                                       lightInfo;
    DrawFrameContext                                frameContext;
    std::vector<std::shared_ptr<DrawBatchConstant>> batchContext;
#ifdef DEBUG
    std::vector<DEBUG_DrawBatch> DEBUG_Batches;  // The first batch is static with identity transformation
#endif
};
}  // namespace newbieGE