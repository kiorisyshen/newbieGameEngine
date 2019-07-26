#pragma once
#import <MetalKit/MetalKit.h>
#include "GraphicsManager.hpp"
#include "geommath.hpp"

namespace newbieGE
{
struct MtlDrawBatchContext : public DrawBatchConstant {
    uint32_t         index_offset;
    MTLPrimitiveType index_mode;
    uint32_t         index_count;
    MTLIndexType     index_type;
    uint32_t         property_count;
    uint32_t         property_offset;
    int32_t          materialIdx;
};
}

@interface MetalRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)view;

- (void)drawBatch:(const std::vector<std::shared_ptr<DrawBatchConstant>>&)batches;

- (uint32_t)createTexture:(const newbieGE::Image&)image;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray&)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray&)index_array;

- (void)setLightInfo:(const LightInfo&)lightInfo;

- (void)setPerFrameConstants:(const DrawFrameContext&)context;

- (void)setPerBatchConstants:(const std::vector<std::shared_ptr<DrawBatchConstant>>&)batches;

- (void)loadMetal;

- (void)Finalize;

- (void)beginFrame;

- (void)endFrame;

- (void)beginPass;

- (void)endPass;

- (void)beginCompute;

- (void)endCompute;

#ifdef DEBUG
- (void)DEBUG_SetBuffer:(const std::vector<DEBUG_DrawBatch>&)debugBatches;

- (void)DEBUG_ClearDebugBuffers;

- (void)DEBUG_DrawDebug:(const std::vector<DEBUG_DrawBatch>&)debugBatches;

#endif

@end
