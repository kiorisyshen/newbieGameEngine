#include "CocoaMetalApplication.h"
#include <stdio.h>
#include <climits>
#include <cstring>

#import "MetalView.h"

using namespace newbieGE;

int CocoaMetalApplication::Initialize() {
    int result = 0;
    
    @autoreleasepool {
        result     = CocoaApplication::Initialize();
        if (result) {
            return result;
        }

        MetalView *pView = [[MetalView new] initWithFrame:CGRectMake(0, 0, m_Config.screenWidth, m_Config.screenHeight)];

        [m_pWindow setContentView:pView];

        result = BaseApplication::Initialize();
    }

    return result;
}

void CocoaMetalApplication::Tick() {
    @autoreleasepool {
        CocoaApplication::Tick();
        [[m_pWindow contentView] setNeedsDisplay:YES];
    }
}

void CocoaMetalApplication::Finalize() {
    @autoreleasepool {
        CocoaApplication::Finalize();
    }
}
