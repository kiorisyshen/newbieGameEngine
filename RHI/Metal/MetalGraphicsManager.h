#pragma once
#include <string>
#include <unordered_map>
#include <vector>
#include "GraphicsManager.hpp"
#include "geommath.hpp"
#include "portable.hpp"

OBJC_CLASS(MetalRenderer);

namespace newbieGE
{
class MetalGraphicsManager : public GraphicsManager
{
   public:
    int  Initialize() final;
    void Finalize() final;

    void SetRenderer(MetalRenderer* renderer) { m_pRenderer = renderer; }

    //    void RenderBuffers() final;

    void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstants>>& batches) final;

#ifdef DEBUG
    void DEBUG_ClearDebugBuffers() final;
    void DEBUG_SetBuffer() final;
#endif

   protected:
    void BeginScene(const Scene& scene) final;
    void EndScene() final;

    void BeginFrame() final;
    void EndFrame() final;

    void BeginPass() final;
    void EndPass() final;

    void BeginCompute() final;
    void EndCompute() final;

#ifdef DEBUG
    void DEBUG_DrawDebug() final;
#endif

   private:
    void InitializeBuffers(const Scene& scene);
    void SetPerFrameConstants() final;
    void SetPerBatchConstants() final;

    MetalRenderer* m_pRenderer;
};

}  // namespace newbieGE
