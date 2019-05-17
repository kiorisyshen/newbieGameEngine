#import <MetalKit/MetalKit.h>

#import "MetalRenderer.h"
#import "MetalGraphicsManager.h"

using namespace newbieGE;

@implementation MetalRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    MTKView* _mtkView;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
    MTLRenderPassDescriptor* _renderPassDescriptor;
    
    id<MTLRenderCommandEncoder> _renderEncoder;
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
    }

    return self;
}

- (void)initialize
{
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
        id <MTLRenderCommandEncoder> render_encoder =
        [_commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        [render_encoder endEncoding];
        [_commandBuffer presentDrawable:_mtkView.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU
    [_commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}


@end
