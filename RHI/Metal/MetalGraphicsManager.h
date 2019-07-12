#pragma once
#include "GraphicsManager.hpp"
#include "geommath.hpp"
#include <unordered_map>
#include <vector>
#include <string>
#include "portable.hpp"

OBJC_CLASS(MetalRenderer);

namespace newbieGE
{
class MetalGraphicsManager : public GraphicsManager
{
public:
    int Initialize() final;
    void Finalize() final;

    void SetRenderer(MetalRenderer *renderer) { m_pRenderer = renderer; }

//    void RenderBuffers() final;
    
    void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstants>>& batches) final;
//#ifdef DEBUG
//    void DrawLine(const Vector3f &from, const Vector3f &to, const Vector3f &color) final;
//    void DrawBox(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color) final;
//    void ClearDebugBuffers() final;
//#endif

private:
    void InitializeBuffers(const Scene& scene);
    void SetPerFrameConstants() final;
    void SetPerBatchConstants() final;
    
    void BeginScene(const Scene& scene) final;
    void EndScene() final;
    
    void BeginFrame() final;
    void EndFrame() final;
    
    void BeginPass() final;
    void EndPass() final;
    
    void BeginCompute() final;
    void EndCompute() final;

    MetalRenderer *m_pRenderer;
};

} // namespace newbieGE
