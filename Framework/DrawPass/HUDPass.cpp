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
//    g_pGraphicsManager->BeginForwardPass();
//    g_pGraphicsManager->DEBUG_DrawOverlay(0, left, top, 0.35f, 0.35f);
    for (auto shadowMap : frame.frameContext.shadowMap) {
        g_pGraphicsManager->DEBUG_DrawOverlay(shadowMap, left, top, 0.35f, 0.35f);
        top -= 0.45f;
    }
    g_pGraphicsManager->EndHUDPass();
#endif
}
