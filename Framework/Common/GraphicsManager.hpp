#pragma once
#include "FrameStructure.hpp"
#include "IDrawPass.hpp"
#include "IRuntimeModule.hpp"
#include "Polyhedron.hpp"
#include "Scene.hpp"
#include "cbuffer.h"
#include "geommath.hpp"

namespace newbieGE
{
class GraphicsManager : implements IRuntimeModule
{
   public:
    virtual ~GraphicsManager() = default;

    virtual int  Initialize() override;
    virtual void Finalize() override;

    void Tick() override;

    virtual void RenderBuffers() final;

    virtual void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstants>>& batches)
    {
    }

#ifdef DEBUG
    virtual void DEBUG_ToggleDebugInfo() final;
    virtual bool DEBUG_IsShowDebug() final;

    virtual void DEBUG_SetDrawPointParam(const Point3& point, const Vector3f& color) final;
    virtual void DEBUG_SetDrawPointSetParam(const PointSet& point_set, const Vector3f& color) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f& from, const Vector3f& to, const Vector3f& color) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList& vertices, const Vector3f& color) final;

    virtual void DEBUG_SetDrawPolygonParam(const Face& face, const Vector3f& color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron& polyhedron, const Vector3f& color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron& polyhedron, const Matrix4X4f& trans,
                                              const Vector3f& color) final;
    virtual void DEBUG_SetDrawBoxParam(const Vector3f& bbMin, const Vector3f& bbMax, const Vector3f& color) final;

    virtual void DEBUG_SetBuffer() = 0;
    virtual void DEBUG_ClearDebugBuffers();
#endif

   protected:
    virtual void BeginScene(const Scene& scene);
    virtual void EndScene(){};

    virtual void BeginFrame(){};
    virtual void EndFrame(){};

    virtual void BeginPass(){};
    virtual void EndPass(){};

    virtual void BeginCompute(){};
    virtual void EndCompute(){};

#ifdef DEBUG
    virtual void DEBUG_DrawDebug();

    virtual void DEBUG_SetDrawPointSetParam(const PointSet& point_set, const Vector3f& color,
                                            DEBUG_DrawBatch& batch) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f& from, const Vector3f& to, const Vector3f& color,
                                        DEBUG_DrawBatch& batch) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList& vertices, const Vector3f& color,
                                            DEBUG_DrawBatch& batch) final;
    virtual void DEBUG_SetDrawPolygonParam(const Face& face, const Vector3f& color, DEBUG_DrawBatch& batch) final;
#endif

   private:
    void CalculateCameraMatrix();
    void CalculateLights();
    void UpdateConstants();

    virtual void SetLightInfo(){};
    virtual void SetPerFrameConstants(){};
    virtual void SetPerBatchConstants(){};

   protected:
    uint32_t           m_nFrameIndex = 0;
    std::vector<Frame> m_Frames;
#ifdef DEBUG
    bool m_DEBUG_showFlag;
#endif
};

extern GraphicsManager* g_pGraphicsManager;
}  // namespace newbieGE
