#include "TerrainPass.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;

void TerrainPass::Draw(Frame &frame) {
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::TerrainShader);
    g_pGraphicsManager->SetTerrain(frame.frameContext);
    g_pGraphicsManager->DrawTerrain();
}
