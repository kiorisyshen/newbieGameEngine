#pragma once
#include "CocoaApplication.h"

namespace newbieGE {
    class CocoaMetalApplication : public CocoaApplication {
    public:
        CocoaMetalApplication(GfxConfiguration& config)
            : CocoaApplication(config) {};

        virtual int Initialize();
        virtual void Finalize();
        virtual void Tick();
    };
}
