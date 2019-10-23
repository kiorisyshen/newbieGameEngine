#pragma once
#include <string>
#include <unordered_map>
#include <vector>
#include "GraphicsManager.hpp"
#include "geommath.hpp"
#include "portable.hpp"

OBJC_CLASS(MetalRenderer);

namespace newbieGE {
class MetalGraphicsManager : public GraphicsManager {
   public:
    int Initialize() final;
    void Finalize() final;

    MetalRenderer *GetRendererRef();

    MetalRenderer *GetRenderer();

    void SetRenderer(MetalRenderer *renderer);

    void SetRenderer(void *renderer);

    void UseShaderProgram(const DefaultShaderIndex idx) final;

    void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;
    void DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;
    void DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;

    void BeginForwardPass() final;
    void EndForwardPass() final;

    void BeginHUDPass() final;
    void EndHUDPass() final;

    // Shadow Map
    void BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) final;
    void EndShadowPass(const int32_t shadowmap, const int32_t layerIndex) final;

    int32_t GenerateShadowMapArray(const ShadowMapType type, const uint32_t width, const uint32_t height, const uint32_t count) final;
    void DestroyShadowMaps() final;
    void SetShadowMaps(const Frame &frame) final;

    // skybox
    void SetSkyBox(const DrawFrameContext &context) final;
    void DrawSkyBox() final;

    // terrain
    void SetTerrain(const DrawFrameContext &context) final;
    void DrawTerrain() final;

    // pbr compute shader
    void Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth) final;
    int32_t GenerateAndBindTextureForWrite(const char *id, const uint32_t slot_index, const uint32_t width, const uint32_t height) final;

#ifdef DEBUG
    void DEBUG_ClearDebugBuffers() final;
    void DEBUG_SetBuffer() final;
    void DEBUG_DrawDebug() final;
    void DEBUG_DrawOverlay(const int32_t shadowmap,
                           const int32_t layerIndex,
                           float vp_left, float vp_top,
                           float vp_width, float vp_height) final;
#endif

   protected:
    bool InitializeShaders() final;

    void BeginScene(const Scene &scene) final;
    void EndScene() final;

    void BeginFrame() final;
    void EndFrame() final;

    void BeginCompute() final;
    void EndCompute() final;

    void SetLightInfo(const LightInfo &lightInfo) final;
    void SetPerFrameConstants(const DrawFrameContext &context) final;
    void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) final;

   private:
    void InitializeBuffers(const Scene &scene);
    void InitializeSkyBox(const Scene &scene);
    void InitializeTerrain(const Scene &scene);

    // MetalRenderer *m_pRenderer;
    void *m_pRenderer;
};

}  // namespace newbieGE
