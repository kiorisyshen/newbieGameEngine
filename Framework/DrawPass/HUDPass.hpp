#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class HUDPass : implements IDrawPass {
   public:
    ~HUDPass() = default;

    void Draw(Frame &frame) final;
};
}  // namespace newbieGE
