#pragma once
#include "GameLogic.hpp"

namespace newbieGE
{
class DebugInfo_logic : public GameLogic
{
    int Initialize();
    void Finalize();
    void Tick();

    void OnLeftKey();
    void OnRightKey();
    void OnUpKey();
    void OnDownKey();
};
} // namespace newbieGE