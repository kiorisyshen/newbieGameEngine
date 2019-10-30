#ifdef __OBJC__
#include <Cocoa/Cocoa.h>
#endif

#include "BaseApplication.hpp"

namespace newbieGE {
class CocoaApplication : public BaseApplication {
   public:
    CocoaApplication(GfxConfiguration &config)
        : BaseApplication(config){};

    void Finalize() override;
    // One cycle of the main loop
    void Tick() override;

    void *GetMainWindowHandler() override;
    void CreateMainWindow() override;

#ifdef __OBJC__
    NSWindow *GetWindowRef();
    NSWindow *GetWindow();
    void SetWindow(NSWindow *wind);
#endif

   protected:
    void *m_pWindow;
};
}  // namespace newbieGE
