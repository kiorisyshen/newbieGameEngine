#pragma once
#include "FrameStructure.hpp"
#include "IDrawPass.hpp"
#include "IRuntimeModule.hpp"
#include "Polyhedron.hpp"
#include "Scene.hpp"
#include "cbuffer.h"
#include "geommath.hpp"

namespace newbieGE {
class GraphicsManager : implements IRuntimeModule {
   public:
    virtual ~GraphicsManager() = default;

    virtual int Initialize() override;
    virtual void Finalize() override;

    void Tick() override;

    virtual void UseShaderProgram(const DefaultShaderIndex idx) = 0;

    virtual void RenderBuffers() final;

    virtual void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches)                                   = 0;
    virtual void DrawBatchDepthFromLight(const Light &light, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) = 0;

    virtual void BeginForwardPass() = 0;
    virtual void EndForwardPass()   = 0;

    virtual void BeginHUDPass() = 0;
    virtual void EndHUDPass()   = 0;

    // Shadow Map
    virtual void BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) = 0;
    virtual void EndShadowPass(const int32_t shadowmap, const int32_t layerIndex)   = 0;

    virtual int32_t GenerateShadowMapArray(const uint32_t width, const uint32_t height, const uint32_t count) = 0;
    virtual void DestroyShadowMaps()                                                                          = 0;

    virtual void SetShadowMaps(const Frame &frame) = 0;

#ifdef DEBUG
    virtual void DEBUG_ToggleDebugInfo() final;
    virtual bool DEBUG_IsShowDebug() final;

    virtual void DEBUG_SetDrawPointParam(const Point3 &point, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color) final;

    virtual void DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Vector3f &color) final;
    virtual void DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Matrix4X4f &trans, const Vector3f &color) final;
    virtual void DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color) final;

    virtual void DEBUG_SetBuffer() = 0;
    virtual void DEBUG_ClearDebugBuffers();

    virtual void DEBUG_DrawDebug()                                  = 0;
    virtual void DEBUG_DrawOverlay(const int32_t shadowmap,
                                   float vp_left, float vp_top,
                                   float vp_width, float vp_height) = 0;
#endif

   protected:
    virtual bool InitializeShaders() = 0;  // Need to initialize all shaders in DefaultShaderIndex

    virtual void BeginScene(const Scene &scene);
    virtual void EndScene();

    virtual void BeginFrame() = 0;
    virtual void EndFrame()   = 0;

    virtual void BeginCompute() = 0;
    virtual void EndCompute()   = 0;

    virtual void SetLightInfo(const LightInfo &lightInfo)                                             = 0;
    virtual void SetPerFrameConstants(const DrawFrameContext &context)                                = 0;
    virtual void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) = 0;

    virtual void CalculateCameraMatrix() final;
    virtual void CalculateLights() final;
    virtual void UpdateConstants() final;

#ifdef DEBUG
    virtual void DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color, DEBUG_DrawBatch &batch) final;
    virtual void DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color, DEBUG_DrawBatch &batch) final;
    virtual void DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color, DEBUG_DrawBatch &batch) final;
    virtual void DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color, DEBUG_DrawBatch &batch) final;
#endif

   protected:
    bool m_bFinishInit     = false;
    uint32_t m_nFrameIndex = 0;
    std::vector<Frame> m_Frames;
    std::vector<std::shared_ptr<IDrawPass>> m_DrawPasses;

#ifdef DEBUG
    bool m_DEBUG_showFlag;
#endif
};

extern GraphicsManager *g_pGraphicsManager;
}  // namespace newbieGE
