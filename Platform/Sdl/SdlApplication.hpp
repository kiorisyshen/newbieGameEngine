#pragma once

#include <SDL2/SDL.h>
#include "BaseApplication.hpp"

namespace newbieGE {
class SdlApplication : public BaseApplication {
   public:
    using BaseApplication::BaseApplication;

    int Initialize() override;
    void Finalize() override;
    // One cycle of the main loop
    void Tick() override;

    void *GetMainWindowHandler() override {
        return m_pWindow;
    };
    void CreateMainWindow() override;

   protected:
    void logSDLError(std::ostream &os, const std::string &msg);
    void onResize(int width, int height);

   protected:
    SDL_Window *m_pWindow;

    bool m_bInDrag = false;
};
}  // namespace newbieGE
