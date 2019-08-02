#include "ForwardRenderPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;
using namespace std;

void ForwardRenderPass::Draw(Frame &frame) {
    g_pGraphicsManager->DrawBatch(frame.batchContext, DefaultShaderIndex::BasicShader);

#ifdef DEBUG
    if (g_pGraphicsManager->DEBUG_IsShowDebug()) {
        g_pGraphicsManager->DEBUG_DrawDebug();
    }
#endif
}
