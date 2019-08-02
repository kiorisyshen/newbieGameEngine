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

int MetalGraphicsManager::Initialize() {
    int result = GraphicsManager::Initialize();
    [m_pRenderer Initialize];
    return result;
}

void MetalGraphicsManager::Finalize() {
    GraphicsManager::Finalize();
    [m_pRenderer Finalize];
}

void MetalGraphicsManager::DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches, const DefaultShaderIndex idx) {
    [m_pRenderer drawBatch:batches shaderIndex:idx];
}

void MetalGraphicsManager::SetLightInfo(const LightInfo &lightInfo) {
    [m_pRenderer setLightInfo:lightInfo];
}

void MetalGraphicsManager::SetPerFrameConstants(const DrawFrameContext &context) {
    [m_pRenderer setPerFrameConstants:context];
}

void MetalGraphicsManager::SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &context) {
    [m_pRenderer setPerBatchConstants:context];
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
        //        auto vertexCount = pMesh->GetVertexCount();

        for (decltype(vertexPropertiesCount) i = 0; i < vertexPropertiesCount; i++) {
            const SceneObjectVertexArray &v_property_array = pMesh->GetVertexPropertyArray(i);

            [m_pRenderer createVertexBuffer:v_property_array];
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
            [m_pRenderer createIndexBuffer:index_array];

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

            size_t material_index    = index_array.GetMaterialIndex();
            std::string material_key = pGeometryNode->GetMaterialRef(material_index);
            auto material            = scene.GetMaterial(material_key);

            auto dbc           = make_shared<MtlDrawBatchContext>();
            int32_t texture_id = -1;
            if (material) {
                auto color = material->GetBaseColor();
                if (color.ValueMap) {
                    const Image &image = color.ValueMap->GetTextureImage();
                    texture_id         = [m_pRenderer createTexture:image];
                    dbc->diffuseColor  = {-1.0f, -1.0f, -1.0f, 1.0f};
                } else {
                    dbc->diffuseColor = color.Value;
                }
                color              = material->GetSpecularColor();
                dbc->specularColor = color.Value;
                Parameter param    = material->GetSpecularPower();
                dbc->specularPower = param.Value;
            }
            dbc->materialIdx       = texture_id;
            dbc->index_count       = (uint32_t)index_array.GetIndexCount();
            dbc->index_type        = type;
            dbc->batchIndex        = batch_index++;
            dbc->index_offset      = index_offset++;
            dbc->index_mode        = mode;
            dbc->property_offset   = v_property_offset;
            dbc->property_count    = vertexPropertiesCount;
            dbc->objectLocalMatrix = *(pGeometryNode->GetCalculatedTransform()).get();
            dbc->node              = pGeometryNode;

            m_Frames[m_nFrameIndex].batchContext.push_back(dbc);
        }

        v_property_offset += vertexPropertiesCount;
    }
}

bool MetalGraphicsManager::InitializeShaders() {
    return [m_pRenderer InitializeShaders];
}

void MetalGraphicsManager::BeginScene(const Scene &scene) {
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);

    cout << "BeginScene Done!" << endl;
}

void MetalGraphicsManager::EndScene() {
    GraphicsManager::EndScene();
    [m_pRenderer endScene];
}

void MetalGraphicsManager::BeginFrame() {
    [m_pRenderer beginFrame];
}

void MetalGraphicsManager::EndFrame() {
    [m_pRenderer endFrame];
}

void MetalGraphicsManager::BeginPass(const RenderPassIndex idx) {
    [m_pRenderer beginPass:idx];
}

void MetalGraphicsManager::EndPass(const RenderPassIndex idx) {
    [m_pRenderer endPass:idx];
}

void MetalGraphicsManager::BeginCompute() {
    [m_pRenderer beginCompute];
}

void MetalGraphicsManager::EndCompute() {
    [m_pRenderer endCompute];
}

#ifdef DEBUG
void MetalGraphicsManager::DEBUG_SetBuffer() {
    [m_pRenderer DEBUG_SetBuffer:m_Frames[m_nFrameIndex].DEBUG_Batches];
}

void MetalGraphicsManager::DEBUG_ClearDebugBuffers() {
    GraphicsManager::DEBUG_ClearDebugBuffers();

    [m_pRenderer DEBUG_ClearDebugBuffers];
}

void MetalGraphicsManager::DEBUG_DrawDebug() {
    [m_pRenderer DEBUG_DrawDebug:m_Frames[m_nFrameIndex].DEBUG_Batches];
}

#endif
