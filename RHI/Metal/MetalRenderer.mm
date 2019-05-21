#import <MetalKit/MetalKit.h>

#import "MetalRenderer.h"
#import "MetalGraphicsManager.h"

using namespace newbieGE;

//#ifndef ALIGN
#define ALIGN_TMP(x, a)         (((x) + ((a) - 1)) & ~((a) - 1))
//#endif

// CB size is required to be 256-byte aligned.
const size_t kSizePerFrameConstantBuffer = ALIGN_TMP(sizeof(PerFrameConstants), 256);

@implementation MetalRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    MTKView* _mtkView;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
    MTLRenderPassDescriptor* _renderPassDescriptor;
    id<MTLRenderCommandEncoder> _renderEncoder;
    
    id<MTLRenderPipelineState> _pipelineState;

    std::vector<id<MTLBuffer>> _vertexBuffers;
    std::vector<id<MTLBuffer>> _indexBuffers;
    id<MTLBuffer> _uniformBuffers;
//
//    Matrix4X4f* m_worldMatrix;
//    Matrix4X4f* m_viewMatrix;
//    Matrix4X4f* m_projectionMatrix;
    PerFrameConstants _PFC;
    std::vector<std::shared_ptr<MtlDrawBatchContext> > m_VAO;
    
    // Vertex descriptor specifying how vertices will by laid out for input into our render
    // pipeline and how ModelIO should layout vertices
    MTLVertexDescriptor* _mtlVertexDescriptor;
}


-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    if(self = [super init])
    {
        _mtkView = view;
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(2);
        view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _commandQueue = [_device newCommandQueue];
        
        [self loadMetal];
    }

    return self;
}

- (void)loadMetal
{
    NSError *error = NULL;
    
    NSString *libraryFile = [[NSBundle mainBundle] pathForResource:@"Main" ofType:@"metallib"];
    id <MTLLibrary> myLibrary = [_device newLibraryWithFile:libraryFile error:&error];
//    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [myLibrary newFunctionWithName:@"basic_vert_main"];
    id<MTLFunction> fragmentFunction = [myLibrary newFunctionWithName:@"basic_frag_main"];
    
    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    // Positions.
    _mtlVertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[0].offset = 0;
    _mtlVertexDescriptor.attributes[0].bufferIndex = 0;
    // Position Buffer Layout
    _mtlVertexDescriptor.layouts[0].stride = 12;
    _mtlVertexDescriptor.layouts[0].stepRate = 1;
    _mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    // Normals.
    _mtlVertexDescriptor.attributes[1].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[1].offset = 0;
    _mtlVertexDescriptor.attributes[1].bufferIndex = 1;
    // Normal Buffer Layout
    _mtlVertexDescriptor.layouts[1].stride = 12;
    _mtlVertexDescriptor.layouts[1].stepRate = 1;
    _mtlVertexDescriptor.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    
    _uniformBuffers = [_device newBufferWithLength:kSizePerFrameConstantBuffer
                                           options:MTLResourceStorageModeShared];
    _uniformBuffers.label = [NSString stringWithFormat:@"uniformBuffer"];
    
    if (!_pipelineState)
    {
        // Pipeline State creation could fail if we haven't properly set up our pipeline descriptor.
        //  If the Metal API validation is enabled, we can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode)
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

- (void)tick
{
    // Wait to ensure only GEFSMaxBuffersInFlight are getting processed by any stage in the Metal
    // pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    // Create a new command buffer for each render pass to the current drawable
    _commandBuffer = [_commandQueue commandBuffer];
    _commandBuffer.label = @"myCommand";
    
    // Add completion hander which signals _inFlightSemaphore when Metal and the GPU has fully
    // finished processing the commands we're encoding this frame.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [_commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    _renderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    _renderPassDescriptor.colorAttachments[0].loadAction=MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].storeAction=MTLStoreActionStore;
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.3f, 0.4f, 1.0f);
    
    
    // beginPass
    if(_renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> render_encoder = [_commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        render_encoder.label = @"MyRenderEncoder";
        
        [render_encoder setRenderPipelineState:_pipelineState];
        [render_encoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [render_encoder setCullMode:MTLCullModeBack];
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        [render_encoder pushDebugGroup:@"DrawMesh"];

        std::memcpy(_uniformBuffers.contents, &(_PFC), sizeof(PerFrameConstants));

        [render_encoder setVertexBuffer:_uniformBuffers
                                 offset:0
                                atIndex:10];

        for (const auto& pDbc : m_VAO)
        {
            const MtlDrawBatchContext& dbc = dynamic_cast<const MtlDrawBatchContext&>(*pDbc);
            // Set mesh's vertex buffers
            for (uint32_t bufferIndex = 0; bufferIndex < dbc.property_count; bufferIndex++)
            {
                id<MTLBuffer> vertexBuffer = _vertexBuffers[dbc.property_offset + bufferIndex];
                [render_encoder setVertexBuffer:vertexBuffer
                                         offset:0
                                        atIndex:bufferIndex];
            }
            [render_encoder drawIndexedPrimitives:dbc.index_mode
                                       indexCount:dbc.index_count
                                        indexType:dbc.index_type
                                      indexBuffer:_indexBuffers[dbc.index_offset]
                                indexBufferOffset:0];
        }
        [render_encoder popDebugGroup];
        
        [render_encoder endEncoding];
        [_commandBuffer presentDrawable:_mtkView.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU
    [_commandBuffer commit];
}

- (void)createVertexBuffer:(const SceneObjectVertexArray&)v_property_array
{
    id<MTLBuffer> vertexBuffer;
    auto dataSize = v_property_array.GetDataSize();
	auto pData = v_property_array.GetData();
    vertexBuffer = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _vertexBuffers.push_back(vertexBuffer);
}

- (void)createIndexBuffer:(const SceneObjectIndexArray&)index_array
{
    id<MTLBuffer> indexBuffer;
    auto dataSize = index_array.GetDataSize();
	auto pData = index_array.GetData();
    indexBuffer = [_device newBufferWithBytes:pData length:dataSize options:MTLResourceStorageModeShared];
    _indexBuffers.push_back(indexBuffer);
}

- (void)setPerFrameContext:(const PerFrameConstants&)pfc
{
    _PFC = pfc;
}

- (std::vector<std::shared_ptr<MtlDrawBatchContext> >&)getVAO
{
    return m_VAO;
}

@end
