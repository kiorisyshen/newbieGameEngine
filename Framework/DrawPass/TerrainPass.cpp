#include "TerrainPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;

void TerrainPass::Draw(Frame &frame) {
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::TerrainShader);
    g_pGraphicsManager->SetSkyBox(frame.frameContext);
    g_pGraphicsManager->DrawSkyBox();
}
