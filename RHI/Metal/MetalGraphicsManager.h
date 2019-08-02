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

    void SetRenderer(MetalRenderer *renderer) {
        m_pRenderer = renderer;
    }

    void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches, const DefaultShaderIndex idx) final;

#ifdef DEBUG
    void DEBUG_ClearDebugBuffers() final;
    void DEBUG_SetBuffer() final;
    void DEBUG_DrawDebug() final;
#endif

   protected:
    bool InitializeShaders() final;

    void BeginScene(const Scene &scene) final;
    void EndScene() final;

    void BeginFrame() final;
    void EndFrame() final;

    void BeginPass(const RenderPassIndex idx) final;
    void EndPass(const RenderPassIndex idx) final;

    void BeginCompute() final;
    void EndCompute() final;

    void SetLightInfo(const LightInfo &lightInfo) final;
    void SetPerFrameConstants(const DrawFrameContext &context) final;
    void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) final;

   private:
    void InitializeBuffers(const Scene &scene);

    MetalRenderer *m_pRenderer;
};

}  // namespace newbieGE
