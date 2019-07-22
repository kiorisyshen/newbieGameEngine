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

int MetalGraphicsManager::Initialize()
{
    int result = GraphicsManager::Initialize();
    return result;
}

void MetalGraphicsManager::Finalize()
{
    [m_pRenderer Finalize];
    m_DrawBatchContext.clear();
}

// void MetalGraphicsManager::RenderBuffers() {
//    [m_pRenderer tick:m_DrawBatchContext];
//}

void MetalGraphicsManager::DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstants>>& batches)
{
    [m_pRenderer drawBatch:batches];
}

void MetalGraphicsManager::SetPerFrameConstants() { [m_pRenderer setPerFrameConstants:m_DrawFrameContext]; }

void MetalGraphicsManager::SetPerBatchConstants() { [m_pRenderer setPerBatchConstants:m_DrawBatchContext]; }

void MetalGraphicsManager::InitializeBuffers(const Scene& scene)
{
    m_DrawBatchContext.clear();

    uint32_t batch_index = 0;
    uint32_t v_property_offset = 0;
    uint32_t index_offset = 0;

    for (auto _it : scene.GeometryNodes) {
        auto pGeometryNode = _it.second;
        if (!pGeometryNode->Visible()) {
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
            const SceneObjectVertexArray& v_property_array = pMesh->GetVertexPropertyArray(i);

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
            const SceneObjectIndexArray& index_array = pMesh->GetIndexArray(i);
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

            size_t      material_index = index_array.GetMaterialIndex();
            std::string material_key = pGeometryNode->GetMaterialRef(material_index);
            auto        material = scene.GetMaterial(material_key);

            auto    dbc = make_shared<MtlDrawBatchContext>();
            int32_t texture_id = -1;
            if (material) {
                auto color = material->GetBaseColor();
                if (color.ValueMap) {
                    const Image& image = color.ValueMap->GetTextureImage();
                    texture_id = [m_pRenderer createTexture:image];
                    dbc->m_diffuseColor = {-1.0f, -1.0f, -1.0f, 1.0f};
                } else {
                    dbc->m_diffuseColor = color.Value;
                }
                color = material->GetSpecularColor();
                dbc->m_specularColor = color.Value;
                Parameter param = material->GetSpecularPower();
                // dbc->m_specularPower = param.Value;
            }
            dbc->materialIdx = texture_id;
            dbc->index_count = (uint32_t)index_array.GetIndexCount();
            dbc->index_type = type;
            dbc->batchIndex = batch_index++;
            dbc->index_offset = index_offset++;
            dbc->index_mode = mode;
            dbc->property_offset = v_property_offset;
            dbc->property_count = vertexPropertiesCount;
            dbc->m_objectLocalMatrix = *(pGeometryNode->GetCalculatedTransform()).get();
            dbc->node = pGeometryNode;
            //            [m_pRenderer getPBC].emplace_back(dbc);
            m_DrawBatchContext.push_back(dbc);
        }

        v_property_offset += vertexPropertiesCount;
    }
}

void MetalGraphicsManager::BeginScene(const Scene& scene)
{
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);

    cout << "BeginScene Done!" << endl;
}

void MetalGraphicsManager::EndScene() { GraphicsManager::EndScene(); }

void MetalGraphicsManager::BeginFrame() { [m_pRenderer beginFrame]; }

void MetalGraphicsManager::EndFrame() { [m_pRenderer endFrame]; }

void MetalGraphicsManager::BeginPass() { [m_pRenderer beginPass]; }

void MetalGraphicsManager::EndPass() { [m_pRenderer endPass]; }

void MetalGraphicsManager::BeginCompute() { [m_pRenderer beginCompute]; }

void MetalGraphicsManager::EndCompute() { [m_pRenderer endCompute]; }

#ifdef DEBUG
void MetalGraphicsManager::DEBUG_SetBuffer() { [m_pRenderer DEBUG_SetBuffer:m_DEBUG_Batches]; }

void MetalGraphicsManager::DEBUG_ClearDebugBuffers()
{
    GraphicsManager::DEBUG_ClearDebugBuffers();

    [m_pRenderer DEBUG_ClearDebugBuffers];
}

void MetalGraphicsManager::DEBUG_DrawDebug() { [m_pRenderer DEBUG_DrawDebug:m_DEBUG_Batches]; }

#endif
