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
    int result                 = GraphicsManager::Initialize();
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer Initialize];
    SetRenderer(tmpRenderer);

    return result;
}

void MetalGraphicsManager::Finalize() {
    GraphicsManager::Finalize();
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer Finalize];
    m_pRenderer = nullptr;
}

void MetalGraphicsManager::UseShaderProgram(const DefaultShaderIndex idx) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer useShaderProgram:idx];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer drawBatch:batches];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer drawBatchPBR:batches];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer dispatch:width height:height depth:depth];
    SetRenderer(tmpRenderer);
}

int32_t MetalGraphicsManager::GenerateAndBindTextureForWrite(const char *id, const uint32_t slot_index, const uint32_t width, const uint32_t height) {
    MetalRenderer *tmpRenderer = GetRenderer();
    int32_t ret = [tmpRenderer generateAndBindTextureForWrite:width height:height atIndex:slot_index];
    SetRenderer(tmpRenderer);
    return ret;
}

void MetalGraphicsManager::DrawSkyBox() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer drawSkyBox];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer drawBatchDepthFromLight:light shadowType:type withBatches:batches];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::BeginForwardPass() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer beginForwardPass];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::EndForwardPass() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer endForwardPass];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::BeginHUDPass() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer beginHUDPass];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::EndHUDPass() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer endHUDPass];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::BeginShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer beginShadowPass:shadowmap sliceIdx:layerIndex];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::EndShadowPass(const int32_t shadowmap, const int32_t layerIndex) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer endShadowPass:shadowmap sliceIdx:layerIndex];
    SetRenderer(tmpRenderer);
}

int32_t MetalGraphicsManager::GenerateShadowMapArray(const ShadowMapType type, const uint32_t width, const uint32_t height, const uint32_t count) {
    MetalRenderer *tmpRenderer = GetRenderer();
    int32_t ret = [tmpRenderer createDepthTextureArray:type width:width height:height count:count];
    SetRenderer(tmpRenderer);
    return ret;
}

void MetalGraphicsManager::DestroyShadowMaps() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer destroyShadowMaps];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::SetShadowMaps(const Frame &frame) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer setShadowMaps:frame];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::SetLightInfo(const LightInfo &lightInfo) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer setLightInfo:lightInfo];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::SetSkyBox(const DrawFrameContext &context) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer setSkyBox:context];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::SetPerFrameConstants(const DrawFrameContext &context) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer setPerFrameConstants:context];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer setPerBatchConstants:context];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::InitializeBuffers(const Scene &scene) {
    MetalRenderer *tmpRenderer = GetRenderer();
    
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

            [tmpRenderer createVertexBuffer:v_property_array];
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
            [tmpRenderer createIndexBuffer:index_array];

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
                    texture_id         = [tmpRenderer createTexture:image];

                    dbc->material.diffuseMap = texture_id;
                }

                if (auto &texture = material->GetNormal().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [tmpRenderer createTexture:image];

                    dbc->material.normalMap = texture_id;
                }

                if (auto &texture = material->GetMetallic().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [tmpRenderer createTexture:image];

                    dbc->material.metallicMap = texture_id;
                }

                if (auto &texture = material->GetRoughness().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [tmpRenderer createTexture:image];

                    dbc->material.roughnessMap = texture_id;
                }

                if (auto &texture = material->GetAO().ValueMap) {
                    int32_t texture_id;
                    const Image &image = *texture->GetTextureImage();
                    texture_id         = [tmpRenderer createTexture:image];

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
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::initializeSkyBox(const Scene &scene) {
    MetalRenderer *tmpRenderer = GetRenderer();
    
    if (scene.SkyBox) {
        std::vector<const std::shared_ptr<newbieGE::Image>> images;
        for (uint32_t i = 0; i < 18; i++) {
            auto &texture      = scene.SkyBox->GetTexture(i);
            const auto &pImage = texture.GetTextureImage();
            images.push_back(pImage);
        }

        int32_t tex_index = [tmpRenderer createSkyBox:images];

        for (uint32_t i = 0; i < GfxConfiguration::kMaxInFlightFrameCount; i++) {
            m_Frames[i].frameContext.skybox = tex_index;
        }
    }
    SetRenderer(tmpRenderer);
}

bool MetalGraphicsManager::InitializeShaders() {
    MetalRenderer *tmpRenderer = GetRenderer();
    bool ret = [tmpRenderer InitializeShaders];
    SetRenderer(tmpRenderer);
    return ret;
}

void MetalGraphicsManager::BeginScene(const Scene &scene) {
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);
    initializeSkyBox(scene);

    cout << "[MetalGraphicsManager] BeginScene Done!" << endl;
}

void MetalGraphicsManager::EndScene() {
    MetalRenderer *tmpRenderer = GetRenderer();
    GraphicsManager::EndScene();
    [tmpRenderer endScene];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::BeginFrame() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer beginFrame];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::EndFrame() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer endFrame];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::BeginCompute() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer beginCompute];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::EndCompute() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer endCompute];
    SetRenderer(tmpRenderer);
}

#ifdef DEBUG
void MetalGraphicsManager::DEBUG_SetBuffer() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer DEBUG_SetBuffer:m_Frames[m_nFrameIndex].DEBUG_Batches];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DEBUG_ClearDebugBuffers() {
    MetalRenderer *tmpRenderer = GetRenderer();
    GraphicsManager::DEBUG_ClearDebugBuffers();

    [tmpRenderer DEBUG_ClearDebugBuffers];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DEBUG_DrawDebug() {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer DEBUG_DrawDebug:m_Frames[m_nFrameIndex].DEBUG_Batches];
    SetRenderer(tmpRenderer);
}

void MetalGraphicsManager::DEBUG_DrawOverlay(const int32_t shadowmap,
                                             const int32_t layerIndex,
                                             float vp_left, float vp_top,
                                             float vp_width, float vp_height) {
    MetalRenderer *tmpRenderer = GetRenderer();
    [tmpRenderer DEBUG_DrawOverlay:shadowmap layerIndex:layerIndex left:vp_left top:vp_top width:vp_width height:vp_height];
    SetRenderer(tmpRenderer);
}
#endif
