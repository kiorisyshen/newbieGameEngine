#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"
#include "cbuffer.h"
#include "Scene.hpp"

namespace newbieGE
{
struct DrawBatchConstants : public PerBatchConstants
{
    uint32_t batchIndex;
    std::shared_ptr<SceneGeometryNode> node;

    virtual ~DrawBatchConstants() = default;
};

class GraphicsManager : implements IRuntimeModule
{
public:
    virtual ~GraphicsManager() = default;

    virtual int Initialize() override;
    virtual void Finalize() override;

    void Tick() override;

    virtual void RenderBuffers() final;

    virtual void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstants>> &batches) {}

#ifdef DEBUG
    virtual void DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color) final;
    virtual void DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color) final;
    virtual void DEBUG_ClearDebugBuffers();
#endif

protected:
    virtual void BeginScene(const Scene &scene);
    virtual void EndScene() {}

    virtual void BeginFrame() {}
    virtual void EndFrame() {}

    virtual void BeginPass() {}
    virtual void EndPass() {}

    virtual void BeginCompute() {}
    virtual void EndCompute() {}

#ifdef DEBUG
    virtual void DEBUG_DrawLines(const std::vector<DEBUG_LineParam> &lineParams);
#endif

private:
    void InitConstants();

    void CalculateCameraMatrix();
    void CalculateLights();
    void UpdateConstants();

    virtual void SetPerFrameConstants(){};
    virtual void SetPerBatchConstants(){};

protected:
    PerFrameConstants m_DrawFrameContext;
    std::vector<std::shared_ptr<DrawBatchConstants>> m_DrawBatchContext;

#ifdef DEBUG
    std::vector<DEBUG_LineParam> m_DEBUG_LineParams;
    bool m_DEBUG_showFlag;
#endif
};

extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
