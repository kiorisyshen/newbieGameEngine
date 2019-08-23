#include "ShadowMapPass.hpp"
#include "GraphicsManager.hpp"

using namespace std;
using namespace newbieGE;

void ShadowMapPass::Draw(Frame &frame) {
    if (frame.frameContext.shadowMapLight.size() > 0 ||
        frame.frameContext.cubeShadowMapLight.size() > 0 ||
        frame.frameContext.globalShadowMapLight.size() > 0) {
        g_pGraphicsManager->DestroyShadowMaps();
        frame.frameContext.shadowMapLight.clear();
        frame.frameContext.cubeShadowMapLight.clear();
        frame.frameContext.globalShadowMapLight.clear();
        frame.frameContext.shadowMap       = -1;
        frame.frameContext.cubeShadowMap   = -1;
        frame.frameContext.globalShadowMap = -1;
    }

    // count shadow map
    vector<Light *> lights_cast_shadow;

    for (int32_t i = 0; i < frame.frameContext.numLights; i++) {
        auto &light               = frame.lightInfo.lights[i];
        light.lightShadowMapIndex = -1;

        if (light.lightCastShadow) {
            switch (light.lightType) {
                case LightType::Omni:
                    light.lightShadowMapIndex = frame.frameContext.cubeShadowMapLight.size();
                    frame.frameContext.cubeShadowMapLight.push_back(&light);
                    break;
                case LightType::Spot:
                    light.lightShadowMapIndex = frame.frameContext.shadowMapLight.size();
                    frame.frameContext.shadowMapLight.push_back(&light);
                    break;
                case LightType::Area:
                    light.lightShadowMapIndex = frame.frameContext.shadowMapLight.size();
                    frame.frameContext.shadowMapLight.push_back(&light);
                    break;
                case LightType::Infinity:
                    light.lightShadowMapIndex = frame.frameContext.globalShadowMapLight.size();
                    frame.frameContext.globalShadowMapLight.push_back(&light);
                    break;
                default:
                    assert(0);
            }
        }
    }

    if (frame.frameContext.shadowMapLight.size() > 0) {
        int32_t shadowmapID          = g_pGraphicsManager->GenerateShadowMapArray(m_kNormalShadowMap.type,
                                                                         m_kNormalShadowMap.width, m_kNormalShadowMap.height,
                                                                         frame.frameContext.shadowMapLight.size());
        frame.frameContext.shadowMap = shadowmapID;
    }

    if (frame.frameContext.cubeShadowMapLight.size() > 0) {
        int32_t shadowmapID              = g_pGraphicsManager->GenerateShadowMapArray(m_kCubeShadowMap.type,
                                                                         m_kCubeShadowMap.width, m_kCubeShadowMap.height,
                                                                         frame.frameContext.shadowMapLight.size());
        frame.frameContext.cubeShadowMap = shadowmapID;
    }

    if (frame.frameContext.globalShadowMapLight.size() > 0) {
        int32_t shadowmapID                = g_pGraphicsManager->GenerateShadowMapArray(m_kGlobalShadowMap.type,
                                                                         m_kGlobalShadowMap.width, m_kGlobalShadowMap.height,
                                                                         frame.frameContext.globalShadowMapLight.size());
        frame.frameContext.globalShadowMap = shadowmapID;
    }

    for (auto it : frame.frameContext.shadowMapLight) {
        g_pGraphicsManager->BeginShadowPass(frame.frameContext.shadowMap, it->lightShadowMapIndex);
        g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::ShadowMapShader);
        g_pGraphicsManager->DrawBatchDepthFromLight(*it, frame.batchContext);
        g_pGraphicsManager->EndShadowPass(frame.frameContext.shadowMap, it->lightShadowMapIndex);
    }

    for (auto it : frame.frameContext.cubeShadowMapLight) {
        g_pGraphicsManager->BeginShadowPass(frame.frameContext.cubeShadowMap, it->lightShadowMapIndex);
        g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::ShadowMapShader);
        g_pGraphicsManager->DrawBatchDepthFromLight(*it, frame.batchContext);
        g_pGraphicsManager->EndShadowPass(frame.frameContext.cubeShadowMap, it->lightShadowMapIndex);
    }

    for (auto it : frame.frameContext.globalShadowMapLight) {
        g_pGraphicsManager->BeginShadowPass(frame.frameContext.globalShadowMap, it->lightShadowMapIndex);
        g_pGraphicsManager->UseShaderProgram(DefaultShaderIndex::ShadowMapShader);
        g_pGraphicsManager->DrawBatchDepthFromLight(*it, frame.batchContext);
        g_pGraphicsManager->EndShadowPass(frame.frameContext.globalShadowMap, it->lightShadowMapIndex);
    }
}
