#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class ShadowMapPass : implements IDrawPass {
   public:
    ~ShadowMapPass() = default;

    const ShadowMapDescription m_kNormalShadowMap{512, 512, NormalShadowMapType};
    const ShadowMapDescription m_kCubeShadowMap{512, 512, CubeShadowMapType};
    const ShadowMapDescription m_kGlobalShadowMap{2048, 2048, GlobalShadowMapType};

    void Draw(Frame &frame) final;
};
}  // namespace newbieGE
