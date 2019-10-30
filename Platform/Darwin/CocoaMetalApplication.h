#pragma once
#include "CocoaApplication.h"

namespace newbieGE {
class CocoaMetalApplication : public CocoaApplication {
   public:
    CocoaMetalApplication(GfxConfiguration &config)
        : CocoaApplication(config){};

    void Tick() override;
    void Finalize() override;
    void CreateMainWindow() override;
};
}  // namespace newbieGE
