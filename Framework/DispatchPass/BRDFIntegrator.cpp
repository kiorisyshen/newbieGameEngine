#include "BRDFIntegrator.hpp"
#include "GraphicsManager.hpp"

using namespace newbieGE;

void BRDFIntegrator::Dispatch() {
    g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::PbrBrdfShader);
    int32_t brdf_lut;
    const uint32_t width  = 512u;
    const uint32_t height = 512u;
    const uint32_t depth  = 1u;

    brdf_lut = g_pGraphicsManager->GenerateAndBindTextureForWrite("BRDF_LUT", 0, width, height);
    g_pGraphicsManager->Dispatch(width, height, depth);
}