#include "BaseApplication.hpp"
#ifdef __OBJC__
#include <Cocoa/Cocoa.h>
#endif

namespace newbieGE {
class CocoaApplication : public BaseApplication {
   public:
    CocoaApplication(GfxConfiguration &config)
        : BaseApplication(config){};

    virtual int Initialize();
    virtual void Finalize();
    // One cycle of the main loop
    virtual void Tick();
    
#ifdef __OBJC__
    NSWindow *GetWindowRef();
    NSWindow *GetWindow();
    void SetWindow(NSWindow *wind);
#endif

   protected:
    void *m_pWindow;
};
}  // namespace newbieGE
