#pragma once
#include "IDrawPass.hpp"

namespace newbieGE
{
class ForwardRenderPass : implements IDrawPass
{
   public:
    ~ForwardRenderPass() = default;
    void Draw(Frame& frame) final;
};
}  // namespace newbieGE
