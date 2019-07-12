#pragma once
#include "GameLogic.hpp"

namespace newbieGE
{
class BilliardGameLogic : public GameLogic
{
    virtual int Initialize();
    virtual void Finalize();
    virtual void Tick();

    virtual void OnLeftKey();
};
} // namespace newbieGE