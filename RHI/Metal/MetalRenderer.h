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

- (void)drawBatchPBR:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches;

- (void)drawSkyBox;

- (void)drawTerrain;

- (void)drawBatchDepthFromLight:(const Light &)light
                     shadowType:(const ShadowMapType)type
                    withBatches:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches;

- (void)beginForwardPass;

- (void)endForwardPass;

- (void)beginHUDPass;

- (void)endHUDPass;

- (void)beginShadowPass:(const int32_t)shadowmap
               sliceIdx:(const int32_t)layerIndex;

- (void)endShadowPass:(const int32_t)shadowmap
             sliceIdx:(const int32_t)layerIndex;

- (void)setShadowMaps:(const Frame &)frame;

- (void)destroyShadowMaps;

- (int32_t)createDepthTextureArray:(const ShadowMapType)type
                             width:(const uint32_t)width
                            height:(const uint32_t)height
                             count:(const uint32_t)count;

- (uint32_t)createTexture:(const newbieGE::Image &)image;

- (uint32_t)createSkyBox:(const std::vector<const std::shared_ptr<newbieGE::Image>> &)images;

- (uint32_t)createTerrain:(const std::vector<const std::shared_ptr<newbieGE::Image>> &)images;

- (void)createVertexBuffer:(const newbieGE::SceneObjectVertexArray &)v_property_array;

- (void)createIndexBuffer:(const newbieGE::SceneObjectIndexArray &)index_array;

- (void)setLightInfo:(const LightInfo &)lightInfo;

- (void)setSkyBox:(const DrawFrameContext &)context;

- (void)setTerrain:(const DrawFrameContext &)context;

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

- (int32_t)generateAndBindTextureForWrite:(const uint32_t)width
                                   height:(const uint32_t)height
                                  atIndex:(const uint32_t)atIndex;

- (void)dispatch:(const uint32_t)width
          height:(const uint32_t)height
           depth:(const uint32_t)depth;

#ifdef DEBUG
- (void)DEBUG_SetBuffer:(const std::vector<DEBUG_DrawBatch> &)debugBatches;

- (void)DEBUG_ClearDebugBuffers;

- (void)DEBUG_DrawDebug:(const std::vector<DEBUG_DrawBatch> &)debugBatches;

- (void)DEBUG_DrawOverlay:(const int32_t)shadowmap
               layerIndex:(const int32_t)layerIndex
                     left:(float)vp_left
                      top:(float)vp_top
                    width:(float)vp_width
                   height:(float)vp_height;

#endif

@end
