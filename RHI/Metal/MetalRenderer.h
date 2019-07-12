#pragma once
#import <MetalKit/MetalKit.h>
#include "GraphicsManager.hpp"
#include "geommath.hpp"

namespace newbieGE
{
struct MtlDrawBatchContext : public DrawBatchConstants
{
    uint32_t index_offset;
    MTLPrimitiveType index_mode;
    uint32_t index_count;
    MTLIndexType index_type;
    uint32_t property_count;
    uint32_t property_offset;
    int32_t materialIdx;
};
}

@interface MetalRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

- (void)drawBatch:(const std::vector<std::shared_ptr<DrawBatchConstants>> &)batches;

- (uint32_t)createTexture:(const newbieGE::Image &)image;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray &)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray &)index_array;

- (void)setPerFrameConstants:(const PerFrameConstants &)context;

- (void)setPerBatchConstants:(const std::vector<std::shared_ptr<DrawBatchConstants>> &)batches;

- (void)loadMetal;

- (void)Finalize;


- (void)beginFrame;

- (void)endFrame;

- (void)beginPass;

- (void)endPass;

- (void)beginCompute;

- (void)endCompute;

@end
