#pragma once
#import <MetalKit/MetalKit.h>
#include "GraphicsManager.hpp"
#include "geommath.hpp"
#include "SceneObject.hpp"

namespace newbieGE {
    struct MtlDrawBatchContext : PerBatchConstants{
        uint32_t batchIndex;
        uint32_t index_offset;
        MTLPrimitiveType index_mode;
        std::vector<uint32_t> index_counts;
        std::vector<MTLIndexType> index_types;
        uint32_t property_count;
        uint32_t property_offset;
    };
}

@interface MetalRenderer : NSObject

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

-(void)tick;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray&)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray&)index_array;

- (void)setPerFrameContext:(const newbieGE::PerFrameConstants&)pfc;

- (std::vector<std::shared_ptr<newbieGE::MtlDrawBatchContext> >&)getPBC;

- (void)loadMetal;

- (void)Finalize;

@end
