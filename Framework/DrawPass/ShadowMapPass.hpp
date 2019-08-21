#pragma once
#include "IDrawPass.hpp"

namespace newbieGE {
class ShadowMapPass : implements IDrawPass {
   public:
    ~ShadowMapPass() = default;

    const uint32_t kShadowMapWidth        = 512;   // normal shadow map
    const uint32_t kShadowMapHeight       = 512;   // normal shadow map
    const uint32_t kCubeShadowMapWidth    = 512;   // cube shadow map
    const uint32_t kCubeShadowMapHeight   = 512;   // cube shadow map
    const uint32_t kGlobalShadowMapWidth  = 2048;  // shadow map for sun light
    const uint32_t kGlobalShadowMapHeight = 2048;  // shadow map for sun light

    void Draw(Frame &frame) final;
};
}  // namespace newbieGE
