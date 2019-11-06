#pragma once
#include <string>
#include <unordered_map>
#include <vector>
#include "GraphicsManager.hpp"
#include "IApplication.hpp"
#include "IPhysicsManager.hpp"
#include "SceneManager.hpp"
#include "geommath.hpp"

namespace newbieGE {
struct OpenGLDrawBatchContext : public DrawBatchConstant {
    uint32_t vao;
    uint32_t mode;
    uint32_t type;
    int32_t count;
};

struct OpenGLDrawTerrainPatchContext : public PerTerrainPatchConstants {
    uint32_t vao;
    uint32_t mode;
    uint32_t type;
    int32_t count;
};

class OpenGLGraphicsManagerCommonBase : public GraphicsManager {
   public:
    int Initialize() final;

    void ResizeCanvas(int32_t width, int32_t height) final;

    void UseShaderProgram(const DefaultShaderIndex idx) final;

    void DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;
    void DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;
    void DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) final;

    void BeginForwardPass() final {  // Empty
    }
    void EndForwardPass() final {  // Empty
    }

    void BeginHUDPass() final {  // Empty
    }
    void EndHUDPass() final {  // Empty
    }

    // Shadow Map
    void BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) final {  // Empty
    }
    void EndShadowPass(const int32_t shadowmap, const int32_t layerIndex) final {  // Empty
    }

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

    void BeginCompute() final {  // Empty
    }
    void EndCompute() final {  // Empty
    }

    void SetLightInfo(const LightInfo &lightInfo) final;
    void SetPerFrameConstants(const DrawFrameContext &context) final;
    void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) final;

    bool setShaderParameter(const char *paramName, const Matrix4X4f &param);
    bool setShaderParameter(const char *paramName, const Matrix4X4f *param, const int32_t count);
    bool setShaderParameter(const char *paramName, const Vector4f &param);
    bool setShaderParameter(const char *paramName, const Vector3f &param);
    bool setShaderParameter(const char *paramName, const Vector2f &param);
    bool setShaderParameter(const char *paramName, const float param);
    bool setShaderParameter(const char *paramName, const int32_t param);
    bool setShaderParameter(const char *paramName, const uint32_t param);
    bool setShaderParameter(const char *paramName, const bool param);
    int32_t GetTexture(const char *id);

    virtual void getOpenGLTextureFormat(const Image &img, uint32_t &format, uint32_t &internal_format, uint32_t &type) final;

   private:
    void InitializeBuffers(const Scene &scene);
    void InitializeSkyBox(const Scene &scene);
    void InitializeTerrain(const Scene &scene);

    std::vector<Point4> cpuTerrainQuadTessellation(const std::array<Point4, 4> &controlPts, const Matrix4X4f &toScreenTransM);

    // --------------------
    // Private Variables
    // --------------------
    uint32_t m_CurrentShader;
    std::unordered_map<int32_t, uint32_t> m_ShaderList;

    // Uniform buffers
    uint32_t m_uboDrawFrameConstant[GfxConfiguration::kMaxInFlightFrameCount]        = {0};
    uint32_t m_uboDrawBatchConstant[GfxConfiguration::kMaxInFlightFrameCount]        = {0};
    uint32_t m_uboLightInfo[GfxConfiguration::kMaxInFlightFrameCount]                = {0};
    uint32_t m_uboDrawTerrainPatchConstant[GfxConfiguration::kMaxInFlightFrameCount] = {0};

    std::vector<uint32_t> m_Buffers;                       // Vertex & index buffer
    std::unordered_map<std::string, uint32_t> m_Textures;  // Textures

    std::vector<OpenGLDrawTerrainPatchContext> m_TerrainPPC;
};
}  // namespace newbieGE
