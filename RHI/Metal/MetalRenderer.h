#pragma once
#import <MetalKit/MetalKit.h>
#include "GraphicsManager.hpp"
#include "geommath.hpp"

namespace newbieGE {
    struct MtlDrawBatchContext : DrawBatchConstants{
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

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

-(void)tick;

- (uint32_t)createTexture:(const newbieGE::Image&)image;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray&)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray&)index_array;

- (void)setPerFrameContext:(const newbieGE::PerFrameConstants&)pfc;

- (std::vector<std::shared_ptr<newbieGE::MtlDrawBatchContext> >&)getPBC;

- (void)loadMetal;

- (void)Finalize;

@end
