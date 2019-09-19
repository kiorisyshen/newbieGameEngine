#import <MetalKit/MetalKit.h>

#include "IApplication.hpp"
#include "IDrawPass.hpp"
#import "MetalGraphicsManager.h"
#import "MetalRenderer.h"

#if !__has_feature(objc_arc)
#error "ARC is off"
#endif

using namespace newbieGE;

struct ShaderState {
    id<MTLRenderPipelineState> pipelineState;
    id<MTLDepthStencilState> depthStencilState;
};

@implementation MetalRenderer {
    dispatch_semaphore_t _inFlightSemaphore;
    MTKView *_mtkView;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
    id<MTLRenderCommandEncoder> _renderEncoder;
    id<MTLBlitCommandEncoder> _blitEncoder;

    id<MTLSamplerState> _sampler0;
    std::vector<id<MTLTexture>> _textures;

    std::array<id<MTLTexture>, num_ShadowMapType> _lightDepthArray;
    std::array<std::vector<id<MTLTexture>>, num_ShadowMapType> _lightDepthList;

    std::vector<id<MTLBuffer>> _vertexBuffers;
    std::vector<id<MTLBuffer>> _indexBuffers;
    id<MTLBuffer> _uniformBuffers;
    id<MTLBuffer> _lightInfo;

#ifdef DEBUG
    id<MTLBuffer> _DEBUG_Buffer;
#endif

    std::unordered_map<int32_t, MTLRenderPassDescriptor *> _renderPassDescriptors;
    std::unordered_map<int32_t, ShaderState> _renderPassStates;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    if (self = [super init]) {
        _mtkView           = view;
        _device            = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(GfxConfiguration::kMaxInFlightFrameCount);
        _commandQueue      = [_device newCommandQueue];
    }

    return self;
}

- (bool)InitializeShaders {
    bool succ = true;

    NSError *error = NULL;

    NSString *libraryFile    = [[NSBundle mainBundle] pathForResource:@"Main" ofType:@"metallib"];
    id<MTLLibrary> myLibrary = [_device newLibraryWithFile:libraryFile error:&error];
    if (!myLibrary) {
        NSLog(@"Failed to in create metal library, error %@", error);
        succ = false;
    }

    MTLVertexDescriptor *mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    // --------------
    // Basic shaders
    {
        id<MTLFunction> vertexFunction   = [myLibrary newFunctionWithName:@"basic_vert_main"];
        id<MTLFunction> fragmentFunction = [myLibrary newFunctionWithName:@"basic_frag_main"];

        // Vertex descriptor specifying how vertices will by laid out for input into
        // our render pipeline and how ModelIO should layout vertices
        //        MTLVertexDescriptor *mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
        // Positions.
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributePosition].format      = MTLVertexFormatFloat3;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributePosition].offset      = 0;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributePosition].bufferIndex = 0;
        // Position Buffer Layout
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributePosition].stride       = 12;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributePosition].stepRate     = 1;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributePosition].stepFunction = MTLVertexStepFunctionPerVertex;
        // Normals.
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeNormal].format      = MTLVertexFormatFloat3;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeNormal].offset      = 0;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeNormal].bufferIndex = 1;
        // Normal Buffer Layout
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeNormal].stride       = 12;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeNormal].stepRate     = 1;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeNormal].stepFunction = MTLVertexStepFunctionPerVertex;
        // Texture UV.
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeTexcoord].format      = MTLVertexFormatFloat2;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeTexcoord].offset      = 0;
        mtlVertexDescriptor.attributes[VertexAttribute::VertexAttributeTexcoord].bufferIndex = 2;
        // Texture UV Buffer Layout
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeTexcoord].stride       = 8;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeTexcoord].stepRate     = 1;
        mtlVertexDescriptor.layouts[VertexAttribute::VertexAttributeTexcoord].stepFunction = MTLVertexStepFunctionPerVertex;

        MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"Basic Pipeline";
        pipelineStateDescriptor.sampleCount                     = _mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction                  = vertexFunction;
        pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
        pipelineStateDescriptor.vertexDescriptor                = mtlVertexDescriptor;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat      = _mtkView.depthStencilPixelFormat;

        ShaderState basicSS;
        basicSS.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!basicSS.pipelineState) {
            NSLog(@"Failed to created basic pipeline state, error %@", error);
            succ = false;
        }
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction       = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled          = YES;
        basicSS.depthStencilState                 = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        _renderPassStates[(int32_t)DefaultShaderIndex::BasicShader] = basicSS;

        MTLRenderPassDescriptor *forwarRenderPassDescriptor = _mtkView.currentRenderPassDescriptor;
        if (forwarRenderPassDescriptor != nil) {
            forwarRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.3f, 0.4f, 1.0f);
        }

        _renderPassDescriptors[(int32_t)RenderPassIndex::ForwardPass] = forwarRenderPassDescriptor;
    }
    // --------------

    // --------------
    // Shadow shaders
    {
        {  // shadow 2d
            id<MTLFunction> vertexFunction                       = [myLibrary newFunctionWithName:@"shadow2D_vert_main"];
            MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineStateDescriptor.label                        = @"Shadow2D Pipeline";
            pipelineStateDescriptor.sampleCount                  = 1;
            pipelineStateDescriptor.vertexFunction               = vertexFunction;
            pipelineStateDescriptor.fragmentFunction             = nil;
            pipelineStateDescriptor.vertexDescriptor             = mtlVertexDescriptor;
            pipelineStateDescriptor.depthAttachmentPixelFormat   = MTLPixelFormatDepth32Float;

            ShaderState shadowSS;
            shadowSS.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            if (!shadowSS.pipelineState) {
                NSLog(@"Failed to created shadow2D pipeline state, error %@", error);
                succ = false;
            }
            MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
            depthStateDesc.depthCompareFunction       = MTLCompareFunctionLessEqual;
            depthStateDesc.depthWriteEnabled          = YES;
            depthStateDesc.frontFaceStencil           = nil;
            depthStateDesc.backFaceStencil            = nil;
            shadowSS.depthStencilState                = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

            _renderPassStates[(int32_t)DefaultShaderIndex::ShadowMap2DShader] = shadowSS;
        }

#ifdef USE_METALCUBEDEPTH
        {  // shadow cube
            id<MTLFunction> vertexFunction                       = [myLibrary newFunctionWithName:@"shadowCube_vert_main"];
            MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineStateDescriptor.label                        = @"ShadowCube Pipeline";
            pipelineStateDescriptor.sampleCount                  = 1;
            pipelineStateDescriptor.vertexFunction               = vertexFunction;
            pipelineStateDescriptor.fragmentFunction             = nil;
            pipelineStateDescriptor.vertexDescriptor             = mtlVertexDescriptor;
            pipelineStateDescriptor.inputPrimitiveTopology       = MTLPrimitiveTopologyClassTriangle;
            pipelineStateDescriptor.depthAttachmentPixelFormat   = MTLPixelFormatDepth32Float;

            ShaderState shadowSS;
            shadowSS.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            if (!shadowSS.pipelineState) {
                NSLog(@"Failed to created shadowCube pipeline state, error %@", error);
                succ = false;
            }
            MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
            depthStateDesc.depthCompareFunction       = MTLCompareFunctionLessEqual;
            depthStateDesc.depthWriteEnabled          = YES;
            depthStateDesc.frontFaceStencil           = nil;
            depthStateDesc.backFaceStencil            = nil;
            shadowSS.depthStencilState                = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

            _renderPassStates[(int32_t)DefaultShaderIndex::ShadowMapCubeShader] = shadowSS;
        }
#endif

        MTLRenderPassDescriptor *renderPassDescriptor        = [MTLRenderPassDescriptor new];
        renderPassDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(1.0f, 1.0f, 1.0f, 1.0f);
        renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        renderPassDescriptor.depthAttachment.loadAction  = MTLLoadActionClear;
        renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        renderPassDescriptor.depthAttachment.clearDepth  = 1.0;

        _renderPassDescriptors[(int32_t)RenderPassIndex::ShadowPass] = renderPassDescriptor;
    }
    // --------------

#ifdef DEBUG
    // --------------
    // Debug shaders
    {
        id<MTLFunction> vertexFunction   = [myLibrary newFunctionWithName:@"debug_vert_main"];
        id<MTLFunction> fragmentFunction = [myLibrary newFunctionWithName:@"debug_frag_main"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"DEBUG Pipeline";
        pipelineStateDescriptor.sampleCount                     = _mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction                  = vertexFunction;
        pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat      = _mtkView.depthStencilPixelFormat;

        ShaderState debugSS;
        debugSS.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!debugSS.pipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
            succ = false;
        }

        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction       = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled          = NO;
        debugSS.depthStencilState                 = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        _renderPassStates[(int32_t)DefaultShaderIndex::DebugShader] = debugSS;
    }
    // --------------

    // --------------
    // 2D overlay shaders
    {
        id<MTLFunction> vertexFunction   = [myLibrary newFunctionWithName:@"overlay_vert_main"];
        id<MTLFunction> fragmentFunction = [myLibrary newFunctionWithName:@"overlay_frag_main"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"Overlay Pipeline";
        pipelineStateDescriptor.vertexFunction                  = vertexFunction;
        pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;

        ShaderState overlaySS;
        overlaySS.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!overlaySS.pipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
            succ = false;
        }
        overlaySS.depthStencilState = nil;

        _renderPassStates[(int32_t)DefaultShaderIndex::Overlay2dShader] = overlaySS;

        MTLRenderPassDescriptor *overlayPassDescriptor        = [MTLRenderPassDescriptor new];
        overlayPassDescriptor.colorAttachments[0].texture     = _mtkView.currentDrawable.texture;
        overlayPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        _renderPassDescriptors[(int32_t)RenderPassIndex::HUDPass] = overlayPassDescriptor;
    }
    // --------------
#endif

    return succ;
}

- (void)Initialize {
    // PerFrameBuffer
    if (!_uniformBuffers) {
        _uniformBuffers       = [_device newBufferWithLength:kSizePerFrameConstantBuffer +
                                                       kSizePerBatchConstantBuffer * GfxConfiguration::kMaxSceneObjectCount
                                               options:MTLResourceStorageModeShared];
        _uniformBuffers.label = [NSString stringWithFormat:@"uniformBuffer"];
    }

    if (!_lightInfo) {
        _lightInfo       = [_device newBufferWithLength:kSizeLightInfo options:MTLResourceStorageModeShared];
        _lightInfo.label = [NSString stringWithFormat:@"lightInfo"];
    }

    // Texture sampler
    if (!_sampler0) {
        MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.minFilter             = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.magFilter             = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.mipFilter             = MTLSamplerMipFilterLinear;
        samplerDescriptor.rAddressMode          = MTLSamplerAddressModeRepeat;
        samplerDescriptor.sAddressMode          = MTLSamplerAddressModeRepeat;
        samplerDescriptor.tAddressMode          = MTLSamplerAddressModeRepeat;
        _sampler0                               = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    }

#ifdef DEBUG
    // Debug line buffer
    if (!_DEBUG_Buffer) {
        _DEBUG_Buffer       = [_device newBufferWithLength:kSizeDebugMaxAtomBuffer * GfxConfiguration::kMaxDebugObjectCount
                                             options:MTLResourceStorageModeShared];
        _DEBUG_Buffer.label = [NSString stringWithFormat:@"DEBUG_Buffer"];
    }
#endif
}

- (void)useShaderProgram:(const DefaultShaderIndex)idx {
    if (_renderPassStates[(int32_t)idx].pipelineState) {
        [_renderEncoder setRenderPipelineState:_renderPassStates[(int32_t)idx].pipelineState];
    }
    if (_renderPassStates[(int32_t)idx].depthStencilState) {
        [_renderEncoder setDepthStencilState:_renderPassStates[(int32_t)idx].depthStencilState];
    }
}

- (void)drawBatch:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches {
    [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [_renderEncoder setCullMode:MTLCullModeBack];

    // Push a debug group allowing us to identify render commands in the GPU
    // Frame Capture tool
    [_renderEncoder pushDebugGroup:@"DrawMesh"];

    [_renderEncoder setVertexBuffer:_uniformBuffers offset:0 atIndex:10];
    [_renderEncoder setFragmentBuffer:_uniformBuffers offset:0 atIndex:10];
    [_renderEncoder setFragmentBuffer:_lightInfo offset:0 atIndex:12];
    [_renderEncoder setFragmentSamplerState:_sampler0 atIndex:0];
    [_renderEncoder setFragmentTexture:_lightDepthArray[NormalShadowMapType] atIndex:1];
    [_renderEncoder setFragmentTexture:_lightDepthArray[CubeShadowMapType] atIndex:2];
    [_renderEncoder setFragmentTexture:_lightDepthArray[GlobalShadowMapType] atIndex:3];

    for (const auto &pDbc : batches) {
        const MtlDrawBatchContext &dbc = dynamic_cast<const MtlDrawBatchContext &>(*pDbc);

        [_renderEncoder setVertexBuffer:_uniformBuffers
                                 offset:kSizePerFrameConstantBuffer + dbc.batchIndex * kSizePerBatchConstantBuffer
                                atIndex:11];

        [_renderEncoder setFragmentBuffer:_uniformBuffers
                                   offset:kSizePerFrameConstantBuffer + dbc.batchIndex * kSizePerBatchConstantBuffer
                                  atIndex:11];

        // Set mesh's vertex buffers
        for (uint32_t bufferIndex = 0; bufferIndex < dbc.property_count; bufferIndex++) {
            id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset + bufferIndex];
            [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:bufferIndex];
        }
        /* well, we have different material for each index buffer so we can not
        * draw them together in future we should group indicies according to its
        * material and draw them together
        */
        if (dbc.materialIdx >= 0) {
            [_renderEncoder setFragmentTexture:_textures[dbc.materialIdx] atIndex:0];
        }
        if (dbc.property_count <= 2) {
            id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset];
            [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:2];
        }

        [_renderEncoder drawIndexedPrimitives:dbc.index_mode
                                   indexCount:dbc.index_count
                                    indexType:dbc.index_type
                                  indexBuffer:_indexBuffers[dbc.index_offset]
                            indexBufferOffset:0];
    }
    [_renderEncoder popDebugGroup];
}

- (void)buildCubeVPsFromLight:(const Light &)light
                           to:(Matrix4X4f *)shadowMatrices {
    const Vector3f direction[6] = {
        {1.0f, 0.0f, 0.0f},    // +X
        {-1.0f, 0.0f, 0.0f},   // -X
        {0.0f, 1.0f, 0.0f},    // +Y
        {0.0f, -1.0f, 0.0f},   // -Y
        {0.0f, 0.0f, 1.0f},    // +Z
        {0.0f, 0.0f, -1.0f}};  // -Z

    const Vector3f up[6] = {
        {0.0f, -1.0f, 0.0f},
        {0.0f, -1.0f, 0.0f},
        {0.0f, 0.0f, 1.0f},
        {0.0f, 0.0f, -1.0f},
        {0.0f, -1.0f, 0.0f},
        {0.0f, -1.0f, 0.0f}};

    float nearClipDistance = 0.1f;
    float farClipDistance  = 10.0f;
    float fieldOfView      = PI / 2.0f;  // 90 degree for each cube map face

    float screenAspect = (float)_lightDepthArray[ShadowMapType::CubeShadowMapType].width / (float)_lightDepthArray[ShadowMapType::CubeShadowMapType].height;
    Matrix4X4f projection;

    // Build the perspective projection matrix.
    BuildPerspectiveFovRHMatrix(projection, fieldOfView, screenAspect, nearClipDistance, farClipDistance);

    Vector3f pos = {light.lightPosition[0], light.lightPosition[1], light.lightPosition[2]};
    for (int32_t i = 0; i < 6; i++) {
        BuildViewRHMatrix(shadowMatrices[i], pos, pos + direction[i], up[i]);
        shadowMatrices[i] = shadowMatrices[i] * projection;
    }
}

- (void)drawBatchDepthFromVP:(const Matrix4X4f &)vpMatrix
                 withBatches:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches {
    [_renderEncoder pushDebugGroup:@"DrawMeshDepth"];

    [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    // [_renderEncoder setCullMode:MTLCullModeFront];
    [_renderEncoder setCullMode:MTLCullModeBack];

    [_renderEncoder setVertexBytes:&(vpMatrix)
                            length:64
                           atIndex:14];

    [_renderEncoder setVertexBuffer:_uniformBuffers offset:0 atIndex:10];

    for (const auto &pDbc : batches) {
        const MtlDrawBatchContext &dbc = dynamic_cast<const MtlDrawBatchContext &>(*pDbc);

        [_renderEncoder setVertexBuffer:_uniformBuffers
                                 offset:kSizePerFrameConstantBuffer + dbc.batchIndex * kSizePerBatchConstantBuffer
                                atIndex:11];

        // Set mesh's vertex buffers
        for (uint32_t bufferIndex = 0; bufferIndex < dbc.property_count; bufferIndex++) {
            id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset + bufferIndex];
            [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:bufferIndex];
        }

        if (dbc.property_count <= 2) {
            id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset];
            [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:2];
        }

        [_renderEncoder drawIndexedPrimitives:dbc.index_mode
                                   indexCount:dbc.index_count
                                    indexType:dbc.index_type
                                  indexBuffer:_indexBuffers[dbc.index_offset]
                            indexBufferOffset:0];
    }
    [_renderEncoder popDebugGroup];
}

- (void)drawBatchDepthFromLight:(const Light &)light
                     shadowType:(const ShadowMapType)type
                    withBatches:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches {
    if (type == ShadowMapType::NormalShadowMapType || type == ShadowMapType::GlobalShadowMapType) {
        [self drawBatchDepthFromVP:light.lightVP withBatches:batches];
    } else if (type == ShadowMapType::CubeShadowMapType) {
#ifdef USE_METALCUBEDEPTH
        [_renderEncoder pushDebugGroup:@"DrawMeshDepth"];
        
        [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [_renderEncoder setCullMode:MTLCullModeFront];
        // [_renderEncoder setCullMode:MTLCullModeBack];
        
        Matrix4X4f shadowMatrices[6];
        [self buildCubeVPsFromLight:light to:shadowMatrices];
        [_renderEncoder setVertexBytes:shadowMatrices
                                length:64 * 6
                               atIndex:15];
        
        [_renderEncoder setVertexBuffer:_uniformBuffers offset:0 atIndex:10];
        
        for (const auto &pDbc : batches) {
            const MtlDrawBatchContext &dbc = dynamic_cast<const MtlDrawBatchContext &>(*pDbc);
            
            [_renderEncoder setVertexBuffer:_uniformBuffers
                                     offset:kSizePerFrameConstantBuffer + dbc.batchIndex * kSizePerBatchConstantBuffer
                                    atIndex:11];
            
            // Set mesh's vertex buffers
            for (uint32_t bufferIndex = 0; bufferIndex < dbc.property_count; bufferIndex++) {
                id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset + bufferIndex];
                [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:bufferIndex];
            }
            
            if (dbc.property_count <= 2) {
                id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset];
                [_renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:2];
            }
            
            [_renderEncoder drawIndexedPrimitives:dbc.index_mode
                                       indexCount:dbc.index_count
                                        indexType:dbc.index_type
                                      indexBuffer:_indexBuffers[dbc.index_offset]
                                indexBufferOffset:0
                                    instanceCount:6];
        }
        [_renderEncoder popDebugGroup];
#else
        // Render 6 faces into _lightDepthList[ShadowMapType::CubeShadowMapType]
        MTLRenderPassDescriptor *renderPassDescriptor = _renderPassDescriptors[(int32_t)RenderPassIndex::ShadowPass];
        if (light.lightShadowMapIndex < 0) {
            assert(0);
        }
        Matrix4X4f shadowMatrices[6];
        [self buildCubeVPsFromLight:light to:shadowMatrices];

        for (uint32_t i = 0; i < 6; ++i) {
            renderPassDescriptor.depthAttachment.texture = _lightDepthList[type][light.lightShadowMapIndex * 6 + i];
            _renderEncoder                               = [_commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            _renderEncoder.label                         = @"ShadowRenderEncoder";
            [self useShaderProgram:DefaultShaderIndex::ShadowMap2DShader];
            [self drawBatchDepthFromVP:shadowMatrices[i] withBatches:batches];
            if (i < 5) {
                [_renderEncoder endEncoding];
            }
        }
#endif
    }
}

- (void)beginForwardPass {
    MTLRenderPassDescriptor *forwarRenderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if (forwarRenderPassDescriptor != nil) {
        forwarRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.3f, 0.4f, 1.0f);
    }
    _renderPassDescriptors[(int32_t)RenderPassIndex::ForwardPass] = forwarRenderPassDescriptor;

    _renderEncoder       = [_commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptors[(int32_t)RenderPassIndex::ForwardPass]];
    _renderEncoder.label = @"ForwardRenderEncoder";
}

- (void)endForwardPass {
    [_renderEncoder endEncoding];
}

- (void)beginHUDPass {
    MTLRenderPassDescriptor *renderPassDescriptor        = _renderPassDescriptors[(int32_t)RenderPassIndex::HUDPass];
    renderPassDescriptor.colorAttachments[0].texture     = _mtkView.currentDrawable.texture;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    _renderEncoder       = [_commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    _renderEncoder.label = @"HUDRenderEncoder";
}

- (void)endHUDPass {
    [_renderEncoder endEncoding];
}

- (void)beginShadowPass:(const int32_t)shadowmap
               sliceIdx:(const int32_t)layerIndex {
#ifndef USE_METALCUBEDEPTH
    if (shadowmap != ShadowMapType::CubeShadowMapType) {
#endif
        MTLRenderPassDescriptor *renderPassDescriptor = _renderPassDescriptors[(int32_t)RenderPassIndex::ShadowPass];
        renderPassDescriptor.depthAttachment.texture  = _lightDepthList[shadowmap][layerIndex];

#ifdef USE_METALCUBEDEPTH
        if (shadowmap == ShadowMapType::CubeShadowMapType) {
            renderPassDescriptor.renderTargetArrayLength = 6;
        }
#endif
        _renderEncoder       = [_commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        _renderEncoder.label = @"ShadowRenderEncoder";
#ifndef USE_METALCUBEDEPTH
    }
#endif
}

- (void)endShadowPass:(const int32_t)shadowmap
             sliceIdx:(const int32_t)layerIndex {
    [_renderEncoder endEncoding];

    // Copy shadow map to shadow map array's slice
    _blitEncoder       = [_commandBuffer blitCommandEncoder];
    _blitEncoder.label = @"ShadowBlitEncoder";
    [_blitEncoder pushDebugGroup:@"CopyToShadowArray"];

    id<MTLTexture> textureSrc, textureDst;
    textureSrc = _lightDepthList[shadowmap][layerIndex];
    textureDst = _lightDepthArray[shadowmap];

    if (shadowmap == ShadowMapType::CubeShadowMapType) {
        for (int i = 0; i < 6; ++i) {
#ifdef USE_METALCUBEDEPTH
            [_blitEncoder copyFromTexture:textureSrc
                              sourceSlice:i
                              sourceLevel:0
                             sourceOrigin:MTLOriginMake(0, 0, 0)
                               sourceSize:MTLSizeMake(textureSrc.width, textureSrc.height, textureSrc.depth)
                                toTexture:textureDst
                         destinationSlice:(layerIndex * 6) + i
                         destinationLevel:0
                        destinationOrigin:MTLOriginMake(0, 0, 0)];
#else
            textureSrc = _lightDepthList[shadowmap][layerIndex * 6 + i];
            [_blitEncoder copyFromTexture:textureSrc
                              sourceSlice:0
                              sourceLevel:0
                             sourceOrigin:MTLOriginMake(0, 0, 0)
                               sourceSize:MTLSizeMake(textureSrc.width, textureSrc.height, textureSrc.depth)
                                toTexture:textureDst
                         destinationSlice:(layerIndex * 6) + i
                         destinationLevel:0
                        destinationOrigin:MTLOriginMake(0, 0, 0)];
#endif
        }
    } else {
        [_blitEncoder copyFromTexture:textureSrc
                          sourceSlice:0
                          sourceLevel:0
                         sourceOrigin:MTLOriginMake(0, 0, 0)
                           sourceSize:MTLSizeMake(textureSrc.width, textureSrc.height, textureSrc.depth)
                            toTexture:textureDst
                     destinationSlice:layerIndex
                     destinationLevel:0
                    destinationOrigin:MTLOriginMake(0, 0, 0)];
    }
    [_blitEncoder popDebugGroup];
    [_blitEncoder endEncoding];
}

static MTLPixelFormat getMtlPixelFormat(const Image &img) {
    MTLPixelFormat format = MTLPixelFormatRGBA8Unorm;

    switch (img.bitcount) {
        case 8:
            format = MTLPixelFormatR8Unorm;
            break;
        case 16:
            format = MTLPixelFormatRG8Unorm;
            break;
        case 32:
            format = MTLPixelFormatRGBA8Unorm;
            break;
        case 64:
            // Unimplemented
            break;
        case 128:
            // Unimplemented
            break;
        default:
            assert(0);
    }

    return format;
}

- (uint32_t)createTexture:(const Image &)image {
    id<MTLTexture> texture;
    MTLTextureDescriptor *textureDesc = [[MTLTextureDescriptor alloc] init];

    textureDesc.pixelFormat = getMtlPixelFormat(image);
    textureDesc.width       = image.Width;
    textureDesc.height      = image.Height;

    // create the texture obj
    texture = [_device newTextureWithDescriptor:textureDesc];

    // now upload the data
    MTLRegion region = {
        {0, 0, 0},                      // MTLOrigin
        {image.Width, image.Height, 1}  // MTLSize
    };

    [texture replaceRegion:region mipmapLevel:0 withBytes:image.data bytesPerRow:image.pitch];

    uint32_t index = _textures.size();
    _textures.push_back(texture);

    return index;
}

- (int32_t)createDepthTextureArray:(const ShadowMapType)type
                             width:(const uint32_t)width
                            height:(const uint32_t)height
                             count:(const uint32_t)count {
    int32_t ret = (int32_t)type;

    if (ret < 0 || ret >= num_ShadowMapType) {
        ret = -1;
    }

    MTLTextureDescriptor *textureArrayDesc = [[MTLTextureDescriptor alloc] init];
    MTLTextureDescriptor *textureListDesc  = [[MTLTextureDescriptor alloc] init];

    textureArrayDesc.textureType = MTLTextureType2DArray;
    textureArrayDesc.pixelFormat = MTLPixelFormatDepth32Float;
    textureArrayDesc.arrayLength = count;
    textureArrayDesc.width       = width;
    textureArrayDesc.height      = height;
    textureArrayDesc.sampleCount = 1;
    textureArrayDesc.storageMode = MTLStorageModePrivate;
    textureArrayDesc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

    textureListDesc.textureType = MTLTextureType2D;
    textureListDesc.pixelFormat = MTLPixelFormatDepth32Float;
    textureListDesc.width       = width;
    textureListDesc.height      = height;
    textureListDesc.sampleCount = 1;
    textureListDesc.storageMode = MTLStorageModePrivate;
    textureListDesc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

    if (type == ShadowMapType::NormalShadowMapType || type == ShadowMapType::GlobalShadowMapType) {
        if (type == ShadowMapType::NormalShadowMapType) {
            _lightDepthArray[ShadowMapType::NormalShadowMapType] = [_device newTextureWithDescriptor:textureArrayDesc];
        } else {
            _lightDepthArray[ShadowMapType::GlobalShadowMapType] = [_device newTextureWithDescriptor:textureArrayDesc];
        }
        for (uint32_t i = 0; i < count; ++i) {
            id<MTLTexture> textureDepth;
            textureDepth = [_device newTextureWithDescriptor:textureListDesc];
            if (type == ShadowMapType::NormalShadowMapType) {
                _lightDepthList[ShadowMapType::NormalShadowMapType].push_back(textureDepth);
            } else {
                _lightDepthList[ShadowMapType::GlobalShadowMapType].push_back(textureDepth);
            }
        }
    }

    if (type == ShadowMapType::CubeShadowMapType) {
        textureArrayDesc.textureType                       = MTLTextureTypeCubeArray;
        _lightDepthArray[ShadowMapType::CubeShadowMapType] = [_device newTextureWithDescriptor:textureArrayDesc];

        for (uint32_t i = 0; i < count; ++i) {
#ifdef USE_METALCUBEDEPTH
            id<MTLTexture> textureDepth;
            textureListDesc.textureType = MTLTextureTypeCube;
            textureDepth                = [_device newTextureWithDescriptor:textureListDesc];
            _lightDepthList[ShadowMapType::CubeShadowMapType].push_back(textureDepth);
#else
            // Push 6 MTLTextureType2D into depth list to avoid depth cube texture "bug" in Metal
            // Ref: https://stackoverflow.com/questions/57868868/objc-metal-compute-depth-texture-in-cube-form-result-to-strange-depth-map-in-o
            for (uint32_t i = 0; i < 6; ++i) {
                id<MTLTexture> textureDepth;
                textureDepth = [_device newTextureWithDescriptor:textureListDesc];
                _lightDepthList[ShadowMapType::CubeShadowMapType].push_back(textureDepth);
            }
#endif
        }
    }

    return ret;
}

- (void)destroyShadowMaps {
    for (uint32_t i = 0; i < _lightDepthArray.size(); ++i) {
        _lightDepthArray[i] = nil;
    }
    for (uint32_t i = 0; i < _lightDepthList.size(); ++i) {
        _lightDepthList[i].clear();
    }
}

- (void)setShadowMaps:(const Frame &)frame {
}

- (void)createVertexBuffer:(const SceneObjectVertexArray &)v_property_array {
    id<MTLBuffer> vertexBuffer;
    auto dataSize = v_property_array.GetDataSize();
    auto pData    = v_property_array.GetData();
    vertexBuffer  = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _vertexBuffers.push_back(vertexBuffer);
}

- (void)createIndexBuffer:(const SceneObjectIndexArray &)index_array {
    id<MTLBuffer> indexBuffer;
    auto dataSize = index_array.GetDataSize();
    auto pData    = index_array.GetData();
    indexBuffer   = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _indexBuffers.push_back(indexBuffer);
}

- (void)setLightInfo:(const LightInfo &)lightInfo {
    std::memcpy(_lightInfo.contents, &(lightInfo), sizeof(LightInfo));
}

- (void)setPerFrameConstants:(const DrawFrameContext &)context {
    std::memcpy(_uniformBuffers.contents, &(context), sizeof(DrawFrameContext));
}

- (void)setPerBatchConstants:(const std::vector<std::shared_ptr<DrawBatchConstant>> &)batches {
    for (const auto &pDbc : batches) {
        std::memcpy(reinterpret_cast<uint8_t *>(_uniformBuffers.contents) + kSizePerFrameConstantBuffer +
                        pDbc->batchIndex * kSizePerBatchConstantBuffer,
                    &static_cast<const PerBatchConstants &>(*pDbc), sizeof(PerBatchConstants));
    }
}

- (void)Finalize {
    _renderPassDescriptors.clear();
    _renderPassStates.clear();
}

- (void)endScene {
    _textures.clear();
    _vertexBuffers.clear();
    _indexBuffers.clear();
    [self destroyShadowMaps];
}

- (void)beginFrame {
    // Wait to ensure only GEFSMaxBuffersInFlight are getting processed by any
    // stage in the Metal pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    // Create a new command buffer for each render pass to the current drawable
    _commandBuffer       = [_commandQueue commandBuffer];
    _commandBuffer.label = @"myCommand";

    // Add completion hander which signals _inFlightSemaphore when Metal and the
    // GPU has fully finished processing the commands we're encoding this frame.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [_commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
      dispatch_semaphore_signal(block_sema);
    }];
}

- (void)endFrame {
    [_commandBuffer presentDrawable:_mtkView.currentDrawable];

    // Finalize rendering here & push the command buffer to the GPU
    [_commandBuffer commit];
}

- (void)beginCompute {
    //    // Create a new command buffer for each render pass to the current drawable
    //    _computeCommandBuffer = [_commandQueue commandBuffer];
    //    _computeCommandBuffer.label = @"MyComputeCommand";
    //
    //    _computeEncoder = [_computeCommandBuffer computeCommandEncoder];
    //    _computeEncoder.label = @"MyComputeEncoder";
    //    [_computeEncoder setComputePipelineState:_computePipelineState];
}

- (void)endCompute {
    //    [_computeEncoder endEncoding];
    //
    //    // Finalize rendering here & push the command buffer to the GPU
    //    [_computeCommandBuffer commit];
}

#ifdef DEBUG
- (void)DEBUG_SetBuffer:(const std::vector<DEBUG_DrawBatch> &)debugBatches {
    auto offset = debugBatches.size();
    offset      = 0;
    for (auto batch : debugBatches) {
        auto size = sizeof(DEBUG_TriangleParam) * batch.triParams.size();
        std::memcpy(reinterpret_cast<uint8_t *>(_DEBUG_Buffer.contents) + offset, batch.triParams.data(), size);
        offset += ALIGN(size, 256);

        size = sizeof(DEBUG_LineParam) * batch.lineParams.size();
        std::memcpy(reinterpret_cast<uint8_t *>(_DEBUG_Buffer.contents) + offset, batch.lineParams.data(), size);
        offset += ALIGN(size, 256);

        size = sizeof(DEBUG_PointParam) * batch.pointParams.size();
        std::memcpy(reinterpret_cast<uint8_t *>(_DEBUG_Buffer.contents) + offset, batch.pointParams.data(), size);
        offset += ALIGN(size, 256);
    }
}

- (void)DEBUG_ClearDebugBuffers {
}

- (void)DEBUG_DrawDebug:(const std::vector<DEBUG_DrawBatch> &)debugBatches {
    [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [_renderEncoder setCullMode:MTLCullModeBack];
    [_renderEncoder setRenderPipelineState:_renderPassStates[(int32_t)DefaultShaderIndex::DebugShader].pipelineState];
    [_renderEncoder setDepthStencilState:_renderPassStates[(int32_t)DefaultShaderIndex::DebugShader].depthStencilState];
    // Push a debug group allowing us to identify render commands in the GPU
    // Frame Capture tool
    [_renderEncoder pushDebugGroup:@"DrawDebugInfo"];

    [_renderEncoder setVertexBuffer:_uniformBuffers offset:0 atIndex:10];

    auto offset = debugBatches.size();
    offset      = 0;
    for (auto batch : debugBatches) {
        [_renderEncoder setVertexBytes:&batch.pbc length:sizeof(DEBUG_PerBatchConstants) atIndex:8];

        // Draw primitive type debug info
        // Use buffer than setVertexBytes for buffer >= 4096 bytes
        // Triangles
        [_renderEncoder setVertexBuffer:_DEBUG_Buffer offset:offset atIndex:7];
        [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                           vertexStart:0
                           vertexCount:3 * batch.triParams.size()];
        offset += ALIGN(sizeof(DEBUG_TriangleParam) * batch.triParams.size(), 256);

        // Lines
        [_renderEncoder setVertexBuffer:_DEBUG_Buffer offset:offset atIndex:7];
        [_renderEncoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:2 * batch.lineParams.size()];
        offset += ALIGN(sizeof(DEBUG_LineParam) * batch.lineParams.size(), 256);

        // Points
        [_renderEncoder setVertexBuffer:_DEBUG_Buffer offset:offset atIndex:7];
        [_renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:batch.pointParams.size()];
        offset += ALIGN(sizeof(DEBUG_PointParam) * batch.pointParams.size(), 256);
    }

    [_renderEncoder popDebugGroup];
}

struct OverlayIn_VertUV {
    vector_float2 inputPosition;
    vector_float2 uv;
};
- (void)DEBUG_DrawOverlay:(const int32_t)shadowmap
               layerIndex:(const int32_t)layerIndex
                     left:(float)vp_left
                      top:(float)vp_top
                    width:(float)vp_width
                   height:(float)vp_height {
    [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [_renderEncoder setCullMode:MTLCullModeBack];

    [_renderEncoder pushDebugGroup:@"DrawOverlay"];

    const OverlayIn_VertUV OverlayQuad[] =
        {{{vp_left, vp_top}, {0.0, 0.0}},
         {{vp_left, vp_top - vp_height}, {0.0, 1.0}},
         {{vp_left + vp_width, vp_top}, {1.0, 0.0}},
         {{vp_left + vp_width, vp_top - vp_height}, {1.0, 1.0}}};

    [_renderEncoder setVertexBytes:&OverlayQuad
                            length:64
                           atIndex:0];

    [_renderEncoder setFragmentTexture:_lightDepthList[shadowmap][layerIndex] atIndex:0];

    [_renderEncoder setFragmentSamplerState:_sampler0 atIndex:0];
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                       vertexStart:0
                       vertexCount:4];

    [_renderEncoder popDebugGroup];
}

#endif

@end
