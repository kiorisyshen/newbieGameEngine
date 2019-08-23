#include "HUDPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;
using namespace std;

void HUDPass::Draw(Frame &frame) {
#ifdef DEBUG
    // Draw Shadow Maps
    float top  = 0.95f;
    float left = 0.60f;

    g_pGraphicsManager->BeginHUDPass();
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::Overlay2dShader);
    for (auto shadowMapLI : frame.frameContext.globalShadowMapLight) {
        g_pGraphicsManager->DEBUG_DrawOverlay(frame.frameContext.globalShadowMap, shadowMapLI->lightShadowMapIndex, left, top, 0.35f, 0.35f);
        top -= 0.45f;
    }
    g_pGraphicsManager->EndHUDPass();
#endif
}
