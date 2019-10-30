#pragma once
#include "FrameStructure.hpp"
#include "IDispatchPass.hpp"
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

    virtual void UseShaderProgram(const DefaultShaderIndex idx) {
    }

    virtual void RenderBuffers() final;

    virtual void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    }
    virtual void DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    }
    virtual void DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    }

    virtual void BeginForwardPass() {
    }
    virtual void EndForwardPass() {
    }

    virtual void BeginHUDPass() {
    }
    virtual void EndHUDPass() {
    }

    // Shadow Map
    virtual void BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    }
    virtual void EndShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    }

    virtual int32_t GenerateShadowMapArray(const ShadowMapType type, const uint32_t width, const uint32_t height, const uint32_t count) {
        return -1;
    }
    virtual void DestroyShadowMaps() {
    }

    virtual void SetShadowMaps(const Frame &frame) {
    }

    // skybox
    virtual void SetSkyBox(const DrawFrameContext &context) {
    }
    virtual void DrawSkyBox() {
    }

    // terrain
    virtual void SetTerrain(const DrawFrameContext &context) {
    }
    virtual void DrawTerrain() {
    }

    // pbr compute shader
    virtual void Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth) {
    }
    virtual int32_t GenerateAndBindTextureForWrite(const char *id, const uint32_t slot_index, const uint32_t width, const uint32_t height) {
        return -1;
    }

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

    virtual void DEBUG_SetBuffer() {
    }
    virtual void DEBUG_ClearDebugBuffers();

    virtual void DEBUG_DrawDebug() {
    }
    virtual void DEBUG_DrawOverlay(const int32_t shadowmap,
                                   const int32_t layerIndex,
                                   float vp_left, float vp_top,
                                   float vp_width, float vp_height) {
    }
#endif

   protected:
    virtual bool InitializeShaders() {
        return true;
    }  // Need to initialize all shaders in DefaultShaderIndex

    virtual void BeginScene(const Scene &scene);
    virtual void EndScene();

    virtual void BeginFrame() {
    }
    virtual void EndFrame() {
    }

    virtual void BeginCompute() {
    }
    virtual void EndCompute() {
    }

    virtual void SetLightInfo(const LightInfo &lightInfo) {
    }
    virtual void SetPerFrameConstants(const DrawFrameContext &context) {
    }
    virtual void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) {
    }

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
    std::vector<std::shared_ptr<IDispatchPass>> m_InitPasses;

#ifdef DEBUG
    bool m_DEBUG_showFlag;
#endif
};

extern GraphicsManager *g_pGraphicsManager;
}  // namespace newbieGE
