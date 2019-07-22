#pragma once
#ifdef DEBUG
#include "IRuntimeModule.hpp"

namespace newbieGE
{
class DebugManager : implements IRuntimeModule
{
   public:
    int  Initialize() override;
    void Finalize() override;
    void Tick() override;

    void ToggleDebugInfo();

    void DrawDebugInfo() override;

   protected:
    void DrawAxis();
    void DrawGrid();

    bool m_bDrawDebugInfo = false;
};

extern DebugManager* g_pDebugManager;
}  // namespace newbieGE

#endif