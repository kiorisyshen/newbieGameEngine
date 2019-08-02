#import "MetalView.h"
#include "InputManager.hpp"
#include "Metal/MetalGraphicsManager.h"
#import "Metal/MetalRenderer.h"

using namespace newbieGE;

@implementation MetalView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device {
    if (self = [super initWithFrame:frameRect device:device]) {
        [self configure];
    }

    return self;
}

- (void)configure {
    self.device                  = MTLCreateSystemDefaultDevice();
    self.colorPixelFormat        = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    self.framebufferOnly         = YES;
    self.sampleCount             = 4;

    self.paused                = YES;
    self.enableSetNeedsDisplay = YES;

    dynamic_cast<MetalGraphicsManager *>(g_pGraphicsManager)
        ->SetRenderer([[MetalRenderer new] initWithMetalKitView:self]);
}

- (void)drawRect:(CGRect)drawRect {
    g_pGraphicsManager->RenderBuffers();
}

- (void)mouseDown:(NSEvent *)event {
    if ([event type] == NSEventTypeLeftMouseDown) {
        g_pInputManager->LeftMouseButtonDown();
    }
}

- (void)mouseUp:(NSEvent *)event {
    if ([event type] == NSEventTypeLeftMouseUp) {
        g_pInputManager->LeftMouseButtonUp();
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if ([event type] == NSEventTypeLeftMouseDragged) {
        g_pInputManager->LeftMouseDrag([event deltaX], [event deltaY]);
    }
}

- (void)scrollWheel:(NSEvent *)event {
    g_pInputManager->LeftMouseDrag([event deltaX], [event deltaY]);
}

@end
