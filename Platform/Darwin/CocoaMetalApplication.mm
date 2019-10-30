#include "CocoaMetalApplication.h"
#include <stdio.h>
#include <climits>
#include <cstring>

#import "MetalView.h"

using namespace newbieGE;

void CocoaMetalApplication::CreateMainWindow() {
#ifdef __OBJC__
    @autoreleasepool {
        CocoaApplication::CreateMainWindow();

        MetalView *pView = [[MetalView alloc] initWithFrame:CGRectMake(0, 0, m_Config.screenWidth, m_Config.screenHeight)];

        [GetWindowRef() setContentView:pView];
    }
#endif
}

void CocoaMetalApplication::Tick() {
#ifdef __OBJC__
    @autoreleasepool {
        CocoaApplication::Tick();
        [[GetWindowRef() contentView] setNeedsDisplay:YES];
    }
#endif
}

void CocoaMetalApplication::Finalize() {
#ifdef __OBJC__
    @autoreleasepool {
        CocoaApplication::Finalize();
    }
#endif
}
