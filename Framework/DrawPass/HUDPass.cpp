#include "HUDPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;
using namespace std;

void HUDPass::Draw(Frame &frame) {
#ifdef DEBUG
    // Draw Shadow Maps
    float top  = 0.95f;
    float left = 0.30f;

    g_pGraphicsManager->BeginHUDPass();
    for (auto shadowMap : frame.frameContext.shadowMap) {
        g_pGraphicsManager->DEBUG_DrawOverlay(shadowMap, left, top, 0.65f, 0.65f);
        top -= 0.75f;
    }
    g_pGraphicsManager->EndHUDPass();
#endif
}
