#pragma once
#include "SdlApplication.hpp"

namespace newbieGE {
class OpenGLApplication : public SdlApplication {
   public:
    using SdlApplication::SdlApplication;

    void Tick() override;

    void CreateMainWindow() override;

   private:
    SDL_GLContext m_hContext;
};
}  // namespace newbieGE
