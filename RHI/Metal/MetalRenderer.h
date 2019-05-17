#pragma once
#import <MetalKit/MetalKit.h>
#import "GraphicsManager.hpp"

namespace newbieGE {
    struct MtlDrawBatchContext {
        uint32_t batchIndex;
        uint32_t index_count;
        uint32_t index_offset;
        MTLPrimitiveType index_mode;
        MTLIndexType index_type;
        uint32_t property_count;
        uint32_t property_offset;
    };
}

@interface MetalRenderer : NSObject

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

-(void)tick;

-(void)initialize;

@end
