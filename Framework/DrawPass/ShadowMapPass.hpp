#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class ShadowMapPass : implements IDrawPass {
   public:
    ~ShadowMapPass() = default;

    RenderPassIndex GetPassIndex() final {
        return RenderPassIndex::ShadowPass;
    };
    void Draw(Frame &frame) final;
};
}  // namespace newbieGE
