#include "SkyBoxPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;

void SkyBoxPass::Draw(Frame &frame) {
    g_pGraphicsManager->BeginSkyBoxPass();
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::SkyBoxShader);
    g_pGraphicsManager->SetSkyBox(frame.frameContext);
    g_pGraphicsManager->DrawSkyBox();
    g_pGraphicsManager->EndSkyBoxPass();
}
