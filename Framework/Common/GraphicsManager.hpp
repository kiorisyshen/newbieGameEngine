#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"
#include "cbuffer.h"
#include "Scene.hpp"
#include "Polyhedron.hpp"

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
    virtual void DEBUG_SetDrawPointParam(const Point3 &point, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Matrix4X4f &trans, const Vector3f &color) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Matrix4X4f &trans, const Vector3f &color) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList &vertices, const Matrix4X4f &trans, const Vector3f &color) final;

    virtual void DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPolygonParam(const Face &face, const Matrix4X4f &trans, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Matrix4X4f &trans, const Vector3f &color) final;

    virtual void DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color) final;

    virtual void DEBUG_SetBuffer() = 0;
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
    virtual void DEBUG_DrawDebug();
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
    std::vector<DEBUG_PointParam> m_DEBUG_PointParams;
    std::vector<DEBUG_TriangleParam> m_DEBUG_TriParams;

    bool m_DEBUG_showFlag;
#endif
};

extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
