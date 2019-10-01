#include "ForwardRenderPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;
using namespace std;

void ForwardRenderPass::Draw(Frame &frame) {
    g_pGraphicsManager->BeginForwardPass();

    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::SkyBoxShader);
    g_pGraphicsManager->SetSkyBox(frame.frameContext);
    g_pGraphicsManager->DrawSkyBox();

    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::BasicShader);
    g_pGraphicsManager->DrawBatch(frame.batchContext);

#ifdef DEBUG
    if (g_pGraphicsManager->DEBUG_IsShowDebug()) {
        g_pGraphicsManager->DEBUG_DrawDebug();
    }
#endif

    g_pGraphicsManager->EndForwardPass();
}
