#pragma once
#include "IGameLogic.hpp"

namespace newbieGE {
class BilliardGameLogic : public IGameLogic {
    virtual int Initialize();
    virtual void Finalize();
    virtual void Tick();

    virtual void OnLeftKey();
};
}  // namespace newbieGE