#import "MetalView.h"
#import "Metal/MetalRenderer.h"
#include "Metal/MetalGraphicsManager.h"

using namespace newbieGE;

@implementation MetalView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self configure];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self configure];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device
{
    if (self = [super initWithFrame:frameRect device:device])
    {
        [self configure];
    }
    
    return self;
}

- (void)configure
{
    self.device = MTLCreateSystemDefaultDevice();
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    self.framebufferOnly = YES;
    self.sampleCount = 4;
    
    self.paused = YES;
    self.enableSetNeedsDisplay = YES;

    dynamic_cast<MetalGraphicsManager*>(g_pGraphicsManager)->SetRenderer(
        [[MetalRenderer new] initWithMetalKitView:self] 
    );
}

- (void)drawRect:(CGRect)drawRect {
    g_pGraphicsManager->Draw();
//    NSLog(@"draw.");
}

@end
