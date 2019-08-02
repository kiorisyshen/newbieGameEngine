#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class ForwardRenderPass : implements IDrawPass {
   public:
    ~ForwardRenderPass() = default;

    RenderPassIndex GetPassIndex() final {
        return RenderPassIndex::ForwardPass;
    };
    void Draw(Frame &frame) final;
};
}  // namespace newbieGE
