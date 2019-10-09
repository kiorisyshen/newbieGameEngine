#include "MetalGraphicsManager.h"
#include <fstream>
#include <iostream>
#include "AssetLoader.hpp"
#include "IApplication.hpp"
#include "IPhysicsManager.hpp"
#include "MetalRenderer.h"
#include "SceneManager.hpp"

using namespace newbieGE;
using namespace std;

MetalRenderer *MetalGraphicsManager::GetRendererRef() {
    return (__bridge MetalRenderer *)m_pRenderer;
}

MetalRenderer *MetalGraphicsManager::GetRenderer() {
    return (__bridge_transfer MetalRenderer *)m_pRenderer;
}

void MetalGraphicsManager::SetRenderer(MetalRenderer *renderer) {
    m_pRenderer = (__bridge_retained void *)renderer;
}

void MetalGraphicsManager::SetRenderer(void *renderer) {
    m_pRenderer = renderer;
}

int MetalGraphicsManager::Initialize() {
    int result = GraphicsManager::Initialize();
    [GetRendererRef() Initialize];
    return result;
}

void MetalGraphicsManager::Finalize() {
    GraphicsManager::Finalize();
    [GetRendererRef() Finalize];
}

void MetalGraphicsManager::UseShaderProgram(const DefaultShaderIndex idx) {
    [GetRendererRef() useShaderProgram:idx];
}

void MetalGraphicsManager::DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    [GetRendererRef() drawBatch:batches];
}

void MetalGraphicsManager::DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    [GetRendererRef() drawBatchPBR:batches];
}

void MetalGraphicsManager::Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth) {
    [GetRendererRef() dispatch:width height:height depth:depth];
}

int32_t MetalGraphicsManager::GenerateAndBindTextureForWrite(const char *id, const uint32_t slot_index, const uint32_t width, const uint32_t height) {
    return [GetRendererRef() generateAndBindTextureForWrite:width height:height atIndex:slot_index];
}

void MetalGraphicsManager::DrawSkyBox() {
    [GetRendererRef() drawSkyBox];
}

void MetalGraphicsManager::DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    [GetRendererRef() drawBatchDepthFromLight:light shadowType:type withBatches:batches];
}

void MetalGraphicsManager::BeginForwardPass() {
    [GetRendererRef() beginForwardPass];
}

void MetalGraphicsManager::EndForwardPass() {
    [GetRendererRef() endForwardPass];
}

void MetalGraphicsManager::BeginHUDPass() {
    [GetRendererRef() beginHUDPass];
}

void MetalGraphicsManager::EndHUDPass() {
    [GetRendererRef() endHUDPass];
}

void MetalGraphicsManager::BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    [GetRendererRef() beginShadowPass:shadowmap sliceIdx:layerIndex];
}

void MetalGraphicsManager::EndShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    [GetRendererRef() endShadowPass:shadowmap sliceIdx:layerIndex];
}

int32_t MetalGraphicsManager::GenerateShadowMapArray(const ShadowMapType type, const uint32_t width, const uint32_t height, const uint32_t count) {
    return [GetRendererRef() createDepthTextureArray:type width:width height:height count:count];
}

void MetalGraphicsManager::DestroyShadowMaps() {
    [GetRendererRef() destroyShadowMaps];
}

void MetalGraphicsManager::SetShadowMaps(const Frame &frame) {
    [GetRendererRef() setShadowMaps:frame];
}

void MetalGraphicsManager::SetLightInfo(const LightInfo &lightInfo) {
    [GetRendererRef() setLightInfo:lightInfo];
}

void MetalGraphicsManager::SetSkyBox(const DrawFrameContext &context) {
    [GetRendererRef() setSkyBox:context];
}

void MetalGraphicsManager::SetPerFrameConstants(const DrawFrameContext &context) {
    [GetRendererRef() setPerFrameConstants:context];
}

void MetalGraphicsManager::SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) {
    [GetRendererRef() setPerBatchConstants:context];
}

void MetalGraphicsManager::InitializeBuffers(const Scene &scene) {
    for (auto &frame : m_Frames) {
        frame.batchContext.clear();
    }

    uint32_t batch_index       = 0;
    uint32_t v_property_offset = 0;
    uint32_t index_offset      = 0;

    for (auto _it : scene.GeometryNodes) {
        auto pGeometryNode = _it.second.lock();
        if (!pGeometryNode->Visible() || !pGeometryNode) {
            continue;
        }

        auto pGeometry = scene.GetGeometry(pGeometryNode->GetSceneObjectRef());
        assert(pGeometry);
        auto pMesh = pGeometry->GetMesh().lock();
        if (!pMesh) return;

        // -- For vertex --
        // Set the number of vertex properties.
        auto vertexPropertiesCount = pMesh->GetVertexPropertiesCount();

        // Set the number of vertices in the vertex array.
        // auto vertexCount = pMesh->GetVertexCount();

        for (decltype(vertexPropertiesCount) i = 0; i < vertexPropertiesCount; i++) {
            const SceneObjectVertexArray &v_property_array = pMesh->GetVertexPropertyArray(i);

            [GetRendererRef() createVertexBuffer:v_property_array];
        }

        // -- For index --
        // const SceneObjectIndexArray& index_array = pMesh->GetIndexArray(0);

        MTLPrimitiveType mode;
        switch (pMesh->GetPrimitiveType()) {
            case PrimitiveType::kPrimitiveTypePointList:
                mode = MTLPrimitiveTypePoint;
                break;
            case PrimitiveType::kPrimitiveTypeLineList:
                mode = MTLPrimitiveTypeLine;
                break;
            case PrimitiveType::kPrimitiveTypeLineStrip:
                mode = MTLPrimitiveTypeLineStrip;
                break;
            case PrimitiveType::kPrimitiveTypeTriList:
                mode = MTLPrimitiveTypeTriangle;
                break;
            case PrimitiveType::kPrimitiveTypeTriStrip:
                mode = MTLPrimitiveTypeTriangleStrip;
                break;
            default:
                // ignore
                continue;
        }

        auto indexGroupCount = pMesh->GetIndexGroupCount();
        for (decltype(indexGroupCount) i = 0; i < indexGroupCount; i++) {
            const SceneObjectIndexArray &index_array = pMesh->GetIndexArray(i);
            [GetRendererRef() createIndexBuffer:index_array];

            MTLIndexType type;
            switch (index_array.GetIndexType()) {
                case IndexDataType::kIndexDataTypeInt8:
                    // not supported
                    assert(0);
                    break;
                case IndexDataType::kIndexDataTypeInt16:
                    type = MTLIndexTypeUInt16;
                    break;
                case IndexDataType::kIndexDataTypeInt32:
                    type = MTLIndexTypeUInt32;
                    break;
                default:
                    // not supported by OpenGL
                    cerr << "Error: Unsupported Index Type " << index_array << endl;
                    cerr << "Mesh: " << *pMesh << endl;
                    cerr << "Geometry: " << *pGeometry << endl;
                    continue;
            }

            auto material_index = index_array.GetMaterialIndex();
            auto material_key   = pGeometryNode->GetMaterialRef(material_index);
            auto material       = scene.GetMaterial(material_key);

            auto dbc = make_shared<MtlDrawBatchContext>();
            if (material) {
                if (auto &texture = material->GetBaseColor().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [GetRendererRef() createTexture:image];

                    dbc->material.diffuseMap = texture_id;
                }

                if (auto &texture = material->GetNormal().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [GetRendererRef() createTexture:image];

                    dbc->material.normalMap = texture_id;
                }

                if (auto &texture = material->GetMetallic().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [GetRendererRef() createTexture:image];

                    dbc->material.metallicMap = texture_id;
                }

                if (auto &texture = material->GetRoughness().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [GetRendererRef() createTexture:image];

                    dbc->material.roughnessMap = texture_id;
                }

                if (auto &texture = material->GetAO().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [GetRendererRef() createTexture:image];

                    dbc->material.aoMap = texture_id;
                }
            }

            dbc->index_count       = (uint32_t)index_array.GetIndexCount();
            dbc->index_type        = type;
            dbc->batchIndex        = batch_index++;
            dbc->index_offset      = index_offset++;
            dbc->index_mode        = mode;
            dbc->property_offset   = v_property_offset;
            dbc->property_count    = vertexPropertiesCount;
            dbc->objectLocalMatrix = *(pGeometryNode->GetCalculatedTransform()).get();
            dbc->node              = pGeometryNode;

            for (uint32_t i = 0; i < GfxConfiguration::kMaxInFlightFrameCount; i++) {
                m_Frames[i].batchContext.push_back(dbc);
            }
        }

        v_property_offset += vertexPropertiesCount;
    }
}

void MetalGraphicsManager::initializeSkyBox(const Scene &scene) {
    if (scene.SkyBox) {
        std::vector<const std::shared_ptr<newbieGE::Image>> images;
        for (uint32_t i = 0; i < 18; i++) {
            auto &texture      = scene.SkyBox->GetTexture(i);
            const auto &pImage = texture.GetTextureImage();
            images.push_back(pImage);
        }

        int32_t tex_index = [GetRendererRef() createSkyBox:images];

        for (uint32_t i = 0; i < GfxConfiguration::kMaxInFlightFrameCount; i++) {
            m_Frames[i].frameContext.skybox = tex_index;
        }
    }
}

bool MetalGraphicsManager::InitializeShaders() {
    return [GetRendererRef() InitializeShaders];
}

void MetalGraphicsManager::BeginScene(const Scene &scene) {
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);
    initializeSkyBox(scene);

    cout << "[MetalGraphicsManager] BeginScene Done!" << endl;
}

void MetalGraphicsManager::EndScene() {
    GraphicsManager::EndScene();
    [GetRendererRef() endScene];
}

void MetalGraphicsManager::BeginFrame() {
    [GetRendererRef() beginFrame];
}

void MetalGraphicsManager::EndFrame() {
    [GetRendererRef() endFrame];
}

void MetalGraphicsManager::BeginCompute() {
    [GetRendererRef() beginCompute];
}

void MetalGraphicsManager::EndCompute() {
    [GetRendererRef() endCompute];
}

#ifdef DEBUG
void MetalGraphicsManager::DEBUG_SetBuffer() {
    [GetRendererRef() DEBUG_SetBuffer:m_Frames[m_nFrameIndex].DEBUG_Batches];
}

void MetalGraphicsManager::DEBUG_ClearDebugBuffers() {
    GraphicsManager::DEBUG_ClearDebugBuffers();

    [GetRendererRef() DEBUG_ClearDebugBuffers];
}

void MetalGraphicsManager::DEBUG_DrawDebug() {
    [GetRendererRef() DEBUG_DrawDebug:m_Frames[m_nFrameIndex].DEBUG_Batches];
}

void MetalGraphicsManager::DEBUG_DrawOverlay(const int32_t shadowmap,
                                             const int32_t layerIndex,
                                             float vp_left, float vp_top,
                                             float vp_width, float vp_height) {
    [GetRendererRef() DEBUG_DrawOverlay:shadowmap layerIndex:layerIndex left:vp_left top:vp_top width:vp_width height:vp_height];
}
#endif
