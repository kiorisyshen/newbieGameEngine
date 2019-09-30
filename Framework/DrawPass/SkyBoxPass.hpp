#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class SkyBoxPass : implements IDrawPass {
   public:
    ~SkyBoxPass() = default;
    void Draw(Frame &frame) final;
};
}  // namespace newbieGE