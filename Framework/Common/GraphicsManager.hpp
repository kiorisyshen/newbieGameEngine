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

    virtual void RenderBuffers();

private:
    void InitConstants();

    void CalculateCameraMatrix();
    void CalculateLights();
    void UpdateConstants();

    virtual void InitializeBuffers();
    virtual void SetPerFrameConstants(){};
    virtual void SetPerBatchConstants(){};

protected:
    PerFrameConstants m_DrawFrameContext;
    std::vector<std::shared_ptr<DrawBatchConstants>> m_DrawBatchContext;
};

extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
