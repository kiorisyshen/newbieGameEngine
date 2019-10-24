#include "ForwardRenderPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;
using namespace std;

void ForwardRenderPass::Draw(Frame &frame) {
    g_pGraphicsManager->BeginForwardPass();

    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::SkyBoxShader);
    g_pGraphicsManager->SetSkyBox(frame.frameContext);
    g_pGraphicsManager->DrawSkyBox();

    // Draw terrain
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::TerrainShader);
    g_pGraphicsManager->SetTerrain(frame.frameContext);
    g_pGraphicsManager->DrawTerrain();

    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::PbrShader);
    g_pGraphicsManager->DrawBatchPBR(frame.batchContext);

#ifdef DEBUG
    if (g_pGraphicsManager->DEBUG_IsShowDebug()) {
        g_pGraphicsManager->DEBUG_DrawDebug();
    }
#endif

    g_pGraphicsManager->EndForwardPass();
}
