#pragma once
#include "IRuntimeModule.hpp"

namespace newbieGE
{
class DebugManager : implements IRuntimeModule
{
public:
    int Initialize() override;
    void Finalize() override;
    void Tick() override;

#ifdef DEBUG
    virtual void DrawDebugInfo() override;
#endif

    void ToggleDebugInfo();

protected:
    bool m_bDrawDebugInfo = false;
};

extern DebugManager *g_pDebugManager;
} // namespace newbieGE
