#include "ShadowMapPass.hpp"
#include "GraphicsManager.hpp"

using namespace std;
using namespace newbieGE;

void ShadowMapPass::Draw(Frame &frame) {
    if (frame.frameContext.shadowMap.size() > 0) {
        g_pGraphicsManager->DestroyShadowMaps();
        frame.frameContext.shadowMap.clear();
    }

    // count shadow map
    vector<Light *> lights_cast_shadow;

    for (int32_t i = 0; i < frame.frameContext.numLights; i++) {
        auto &light = frame.lightInfo.lights[i];

        if (light.lightCastShadow) {
            lights_cast_shadow.push_back(&light);
        }
    }

    // generate shadow map array
    int32_t shadowmap_index = 0;
    for (auto it : lights_cast_shadow) {
        frame.frameContext.shadowMap.push_back(
            g_pGraphicsManager->GenerateShadowMap(kShadowMapWidth, kShadowMapHeight));
        it->lightShadowMapIndex = shadowmap_index;

        g_pGraphicsManager->BeginShadowPass(*it, it->lightShadowMapIndex);
        g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::ShadowMapShader);
        g_pGraphicsManager->DrawBatch(frame.batchContext);
        g_pGraphicsManager->EndShadowPass(it->lightShadowMapIndex);

        ++shadowmap_index;
    }
}
