#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class TerrainPass : implements IDrawPass {
   public:
    ~TerrainPass() = default;
    void Draw(Frame &frame) final;
};
}  // namespace newbieGE