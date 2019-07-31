#import <MetalKit/MetalKit.h>

#include "IApplication.hpp"
#import "MetalGraphicsManager.h"
#import "MetalRenderer.h"

using namespace newbieGE;

@implementation MetalRenderer {
    dispatch_semaphore_t        _inFlightSemaphore;
    MTKView*                    _mtkView;
    id<MTLDevice>               _device;
    id<MTLCommandQueue>         _commandQueue;
    id<MTLCommandBuffer>        _commandBuffer;
    MTLRenderPassDescriptor*    _renderPassDescriptor;
    id<MTLRenderCommandEncoder> _renderEncoder;

    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState>   _depthState;

    std::vector<id<MTLTexture>> _textures;
    id<MTLSamplerState>         _sampler0;
    std::vector<id<MTLBuffer>>  _vertexBuffers;
    std::vector<id<MTLBuffer>>  _indexBuffers;
    id<MTLBuffer>               _uniformBuffers;
    id<MTLBuffer>               _lightInfo;

#ifdef DEBUG
    id<MTLBuffer>              _DEBUG_Buffer;
    id<MTLRenderPipelineState> _DEBUG_pipelineState;
    MTLVertexDescriptor*       _DEBUG_mtlDebugDescriptor;
    id<MTLDepthStencilState>   _DEBUG_depthState;
#endif

    // Vertex descriptor specifying how vertices will by laid out for input into
    // our render pipeline and how ModelIO should layout vertices
    MTLVertexDescriptor* _mtlVertexDescriptor;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)view;
{
    if (self = [super init]) {
        _mtkView           = view;
        _device            = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(2);
        _commandQueue      = [_device newCommandQueue];

        [self loadMetal];
    }

    return self;
}

- (void)loadMetal
{
    NSError* error = NULL;

    NSString*       libraryFile      = [[NSBundle mainBundle] pathForResource:@"Main" ofType:@"metallib"];
    id<MTLLibrary>  myLibrary        = [_device newLibraryWithFile:libraryFile error:&error];
    id<MTLFunction> vertexFunction   = [myLibrary newFunctionWithName:@"basic_vert_main"];
    id<MTLFunction> fragmentFunction = [myLibrary newFunctionWithName:@"basic_frag_main"];

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    // Positions.
    _mtlVertexDescriptor.attributes[0].format      = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[0].offset      = 0;
    _mtlVertexDescriptor.attributes[0].bufferIndex = 0;
    // Position Buffer Layout
    _mtlVertexDescriptor.layouts[0].stride       = 12;
    _mtlVertexDescriptor.layouts[0].stepRate     = 1;
    _mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    // Normals.
    _mtlVertexDescriptor.attributes[1].format      = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[1].offset      = 0;
    _mtlVertexDescriptor.attributes[1].bufferIndex = 1;
    // Normal Buffer Layout
    _mtlVertexDescriptor.layouts[1].stride       = 12;
    _mtlVertexDescriptor.layouts[1].stepRate     = 1;
    _mtlVertexDescriptor.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
    // Texture UV.
    _mtlVertexDescriptor.attributes[2].format      = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[2].offset      = 0;
    _mtlVertexDescriptor.attributes[2].bufferIndex = 2;
    // Texture UV Buffer Layout
    _mtlVertexDescriptor.layouts[2].stride       = 8;
    _mtlVertexDescriptor.layouts[2].stepRate     = 1;
    _mtlVertexDescriptor.layouts[2].stepFunction = MTLVertexStepFunctionPerVertex;

    // PerFrameBuffer
    _uniformBuffers       = [_device newBufferWithLength:kSizePerFrameConstantBuffer +
                                                   kSizePerBatchConstantBuffer * GfxConfiguration::kMaxSceneObjectCount
                                           options:MTLResourceStorageModeShared];
    _uniformBuffers.label = [NSString stringWithFormat:@"uniformBuffer"];

    _lightInfo       = [_device newBufferWithLength:kSizeLightInfo options:MTLResourceStorageModeShared];
    _lightInfo.label = [NSString stringWithFormat:@"lightInfo"];

    // Texture sampler
    MTLSamplerDescriptor* samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.minFilter             = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter             = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.mipFilter             = MTLSamplerMipFilterLinear;
    samplerDescriptor.rAddressMode          = MTLSamplerAddressModeRepeat;
    samplerDescriptor.sAddressMode          = MTLSamplerAddressModeRepeat;
    samplerDescriptor.tAddressMode          = MTLSamplerAddressModeRepeat;
    _sampler0                               = [_device newSamplerStateWithDescriptor:samplerDescriptor];

    MTLRenderPipelineDescriptor* pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label                           = @"Simple Pipeline";
    pipelineStateDescriptor.sampleCount                     = _mtkView.sampleCount;
    pipelineStateDescriptor.vertexFunction                  = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor                = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat      = _mtkView.depthStencilPixelFormat;

    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    MTLDepthStencilDescriptor* depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction       = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled          = YES;
    _depthState                               = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    if (!_pipelineState) {
        // Pipeline State creation could fail if we haven't properly set up our
        // pipeline descriptor.
        //  If the Metal API validation is enabled, we can find out more information
        //  about what went wrong.  (Metal API validation is enabled by default when
        //  a debug build is run from Xcode)
        NSLog(@"Failed to created pipeline state, error %@", error);
    }

#ifdef DEBUG
    // Debug line buffer
    _DEBUG_Buffer       = [_device newBufferWithLength:kSizeDebugMaxAtomBuffer * GfxConfiguration::kMaxDebugObjectCount
                                         options:MTLResourceStorageModeShared];
    _DEBUG_Buffer.label = [NSString stringWithFormat:@"DEBUG_Buffer"];

    vertexFunction   = [myLibrary newFunctionWithName:@"debug_vert_main"];
    fragmentFunction = [myLibrary newFunctionWithName:@"debug_frag_main"];

    pipelineStateDescriptor                                 = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label                           = @"DEBUG Pipeline";
    pipelineStateDescriptor.sampleCount                     = _mtkView.sampleCount;
    pipelineStateDescriptor.vertexFunction                  = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat      = _mtkView.depthStencilPixelFormat;

    _DEBUG_pipelineState                = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    depthStateDesc                      = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthStateDesc.depthWriteEnabled    = NO;
    _DEBUG_depthState                   = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
#endif
}

- (void)drawBatch:(const std::vector<std::shared_ptr<DrawBatchConstant>>&)batches
{
    if (_renderPassDescriptor != nil) {
        [_renderEncoder setRenderPipelineState:_pipelineState];
        [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [_renderEncoder setCullMode:MTLCullModeBack];
        [_renderEncoder setDepthStencilState:_depthState];
        // Push a debug group allowing us to identify render commands in the GPU
        // Frame Capture tool
        [_renderEncoder pushDebugGroup:@"DrawMesh"];

        [_renderEncoder setVertexBuffer:_uniformBuffers offset:0 atIndex:10];
        [_renderEncoder setFragmentBuffer:_uniformBuffers offset:0 atIndex:10];
        [_renderEncoder setFragmentBuffer:_lightInfo offset:0 atIndex:12];
        [_renderEncoder setFragmentSamplerState:_sampler0 atIndex:0];

        for (const auto& pDbc : batches) {
            const MtlDrawBatchContext& dbc = dynamic_cast<const MtlDrawBatchContext&>(*pDbc);

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
}

static MTLPixelFormat getMtlPixelFormat(const Image& img)
{
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

- (uint32_t)createTexture:(const Image&)image
{
    id<MTLTexture>        texture;
    MTLTextureDescriptor* textureDesc = [[MTLTextureDescriptor alloc] init];

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

- (void)createVertexBuffer:(const SceneObjectVertexArray&)v_property_array
{
    id<MTLBuffer> vertexBuffer;
    auto          dataSize = v_property_array.GetDataSize();
    auto          pData    = v_property_array.GetData();
    vertexBuffer           = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _vertexBuffers.push_back(vertexBuffer);
}

- (void)createIndexBuffer:(const SceneObjectIndexArray&)index_array
{
    id<MTLBuffer> indexBuffer;
    auto          dataSize = index_array.GetDataSize();
    auto          pData    = index_array.GetData();
    indexBuffer            = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _indexBuffers.push_back(indexBuffer);
}

- (void)setLightInfo:(const LightInfo&)lightInfo
{
    std::memcpy(_lightInfo.contents, &(lightInfo), sizeof(LightInfo));
}

- (void)setPerFrameConstants:(const DrawFrameContext&)context
{
    std::memcpy(_uniformBuffers.contents, &(context), sizeof(DrawFrameContext));
}

- (void)setPerBatchConstants:(const std::vector<std::shared_ptr<DrawBatchConstant>>&)batches
{
    for (const auto& pDbc : batches) {
        std::memcpy(reinterpret_cast<uint8_t*>(_uniformBuffers.contents) + kSizePerFrameConstantBuffer +
                        pDbc->batchIndex * kSizePerBatchConstantBuffer,
                    &static_cast<const PerBatchConstants&>(*pDbc), sizeof(PerBatchConstants));
    }
}

- (void)Finalize
{
}

- (void)beginFrame
{
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

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    _renderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if (_renderPassDescriptor != nil) {
        // _renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        // _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStoreAndMultisampleResolve;
        _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.3f, 0.4f, 1.0f);
    }
}

- (void)endFrame
{
    [_commandBuffer presentDrawable:_mtkView.currentDrawable];

    // Finalize rendering here & push the command buffer to the GPU
    [_commandBuffer commit];
}

- (void)beginPass
{
    if (_renderPassDescriptor != nil) {
        _renderEncoder       = [_commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        _renderEncoder.label = @"MyRenderEncoder";
    }
}

- (void)endPass
{
    [_renderEncoder endEncoding];
}

- (void)beginCompute
{
    //    // Create a new command buffer for each render pass to the current drawable
    //    _computeCommandBuffer = [_commandQueue commandBuffer];
    //    _computeCommandBuffer.label = @"MyComputeCommand";
    //
    //    _computeEncoder = [_computeCommandBuffer computeCommandEncoder];
    //    _computeEncoder.label = @"MyComputeEncoder";
    //    [_computeEncoder setComputePipelineState:_computePipelineState];
}

- (void)endCompute
{
    //    [_computeEncoder endEncoding];
    //
    //    // Finalize rendering here & push the command buffer to the GPU
    //    [_computeCommandBuffer commit];
}

#ifdef DEBUG
- (void)DEBUG_SetBuffer:(const std::vector<DEBUG_DrawBatch>&)debugBatches
{
    auto offset = debugBatches.size();
    offset      = 0;
    for (auto batch : debugBatches) {
        auto size = sizeof(DEBUG_TriangleParam) * batch.triParams.size();
        std::memcpy(reinterpret_cast<uint8_t*>(_DEBUG_Buffer.contents) + offset, batch.triParams.data(), size);
        offset += ALIGN(size, 256);

        size = sizeof(DEBUG_LineParam) * batch.lineParams.size();
        std::memcpy(reinterpret_cast<uint8_t*>(_DEBUG_Buffer.contents) + offset, batch.lineParams.data(), size);
        offset += ALIGN(size, 256);

        size = sizeof(DEBUG_PointParam) * batch.pointParams.size();
        std::memcpy(reinterpret_cast<uint8_t*>(_DEBUG_Buffer.contents) + offset, batch.pointParams.data(), size);
        offset += ALIGN(size, 256);
    }
}

- (void)DEBUG_ClearDebugBuffers
{
}

- (void)DEBUG_DrawDebug:(const std::vector<DEBUG_DrawBatch>&)debugBatches
{
    if (_renderPassDescriptor != nil) {
        [_renderEncoder setRenderPipelineState:_DEBUG_pipelineState];
        [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [_renderEncoder setCullMode:MTLCullModeBack];
        [_renderEncoder setDepthStencilState:_DEBUG_depthState];
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
}

#endif

@end
