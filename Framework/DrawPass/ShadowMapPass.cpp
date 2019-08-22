#include "ShadowMapPass.hpp"
#include "GraphicsManager.hpp"

using namespace std;
using namespace newbieGE;

void ShadowMapPass::Draw(Frame &frame) {
    g_pGraphicsManager->DestroyShadowMaps();
    frame.frameContext.shadowMapLayerIndex.clear();
    frame.frameContext.shadowMap = -1;

    // count shadow map
    vector<Light *> lights_cast_shadow;

    for (int32_t i = 0; i < frame.frameContext.numLights; i++) {
        auto &light               = frame.lightInfo.lights[i];
        light.lightShadowMapIndex = -1;

        if (light.lightCastShadow) {
            lights_cast_shadow.push_back(&light);
        }
    }

    int32_t shadowmap            = g_pGraphicsManager->GenerateShadowMapArray(kShadowMapWidth, kShadowMapHeight, lights_cast_shadow.size());
    frame.frameContext.shadowMap = shadowmap;

    // generate shadow map array
    int32_t shadowmap_index = 0;
    for (auto it : lights_cast_shadow) {
        frame.frameContext.shadowMapLayerIndex.push_back(shadowmap_index);
        it->lightShadowMapIndex = shadowmap_index;
        g_pGraphicsManager->BeginShadowPass(shadowmap, shadowmap_index);
        g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::ShadowMapShader);
        g_pGraphicsManager->DrawBatchDepthFromLight(*it, frame.batchContext);
        g_pGraphicsManager->EndShadowPass(shadowmap, shadowmap_index);

        ++shadowmap_index;
    }
}
