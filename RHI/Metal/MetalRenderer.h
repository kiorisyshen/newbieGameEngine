#pragma once
#import <MetalKit/MetalKit.h>
#include "FrameStructure.hpp"
#include "geommath.hpp"

namespace newbieGE {
struct MtlDrawBatchContext : public DrawBatchConstant {
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

- (void)useShaderProgram:(const DefaultShaderIndex)idx;

- (void)drawBatch:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches;

- (void)beginForwardPass;

- (void)endForwardPass;

- (void)beginHUDPass;

- (void)endHUDPass;

- (void)beginShadowPass:(const Light &)light
              shadowmap:(const int32_t)shadowmap;

- (void)endShadowPass:(const int32_t)shadowmap;

- (void)setShadowMaps:(const Frame &)frame;

- (void)destroyShadowMaps;

- (int32_t)createTexture:(const uint32_t)width
                  height:(const uint32_t)height;

- (uint32_t)createTexture:(const newbieGE::Image &)image;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray &)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray &)index_array;

- (void)setLightInfo:(const LightInfo &)lightInfo;

- (void)setPerFrameConstants:(const DrawFrameContext &)context;

- (void)setPerBatchConstants:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches;

- (void)Initialize;

- (void)Finalize;

- (bool)InitializeShaders;

- (void)endScene;

- (void)beginFrame;

- (void)endFrame;

- (void)beginCompute;

- (void)endCompute;

#ifdef DEBUG
- (void)DEBUG_SetBuffer:(const std::vector<DEBUG_DrawBatch> &)debugBatches;

- (void)DEBUG_ClearDebugBuffers;

- (void)DEBUG_DrawDebug:(const std::vector<DEBUG_DrawBatch> &)debugBatches;

- (void)DEBUG_DrawOverlay:(const int32_t)shadowmap
                     left:(float)vp_left
                      top:(float)vp_top
                    width:(float)vp_width
                   height:(float)vp_height;

#endif

@end
