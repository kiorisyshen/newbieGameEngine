#include <iostream>
#include <fstream>
#include "MetalGraphicsManager.h"
#include "AssetLoader.hpp"
#include "IApplication.hpp"
#include "SceneManager.hpp"
#include "MetalRenderer.h"
#include "PhysicsManager.hpp"

using namespace newbieGE;
using namespace std;


int MetalGraphicsManager::Initialize()
{
    int result = GraphicsManager::Initialize();
    if (result) {
        return result;
    }
    
    [m_pRenderer loadMetal];
    
    InitializeBuffers();
    
    return result;
}

void MetalGraphicsManager::Finalize()
{
    [m_pRenderer Finalize];
}

void MetalGraphicsManager::Clear()
{
    GraphicsManager::Clear();
}

void MetalGraphicsManager::Draw()
{
    GraphicsManager::Draw();

    RenderBuffers();
}

void MetalGraphicsManager::RenderBuffers()
{    
    // Set the color shader as the current shader program and set the matrices that it will use for rendering.
    SetPerFrameShaderParameters();
    auto _PBC = [m_pRenderer getPBC];
    for (auto pbc : _PBC) {
        if (void* rigidBody = pbc->node->RigidBody()) {
            Matrix4X4f trans = *pbc->node->GetCalculatedTransform();
            // reset the translation part of the matrix
            memcpy(trans[3], Vector3f(0.0f, 0.0f, 0.0f), sizeof(float) * 3);
            // the geometry has rigid body bounded, we blend the simlation result here.
            Matrix4X4f simulated_result = g_pPhysicsManager->GetRigidBodyTransform(rigidBody);
            // apply the rotation part of the simlation result
            Matrix4X4f rotation;
            BuildIdentityMatrix(rotation);
            memcpy(rotation[0], simulated_result[0], sizeof(float) * 3);
            memcpy(rotation[1], simulated_result[1], sizeof(float) * 3);
            memcpy(rotation[2], simulated_result[2], sizeof(float) * 3);
            trans = trans * rotation;
            
            // replace the translation part of the matrix with simlation result directly
            memcpy(trans[3], simulated_result[3], sizeof(float) * 3);
            
            pbc->m_objectLocalMatrix = trans;
        }
    }
    
    [m_pRenderer tick];
}

bool MetalGraphicsManager::SetPerFrameShaderParameters()
{
    [m_pRenderer setPerFrameContext:m_DrawFrameContext];
    return true;
}

void MetalGraphicsManager::InitializeBuffers()
{
    auto& scene = g_pSceneManager->GetSceneForRendering();

    uint32_t batch_index = 0;
    uint32_t v_property_offset = 0;
    uint32_t index_offset = 0;

    for (auto _it : scene.GeometryNodes)
    {
        auto pGeometryNode = _it.second;
        if (!pGeometryNode->Visible())
        {
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
        auto vertexCount = pMesh->GetVertexCount();

        for (decltype(vertexPropertiesCount) i = 0; i < vertexPropertiesCount; i++)
        {
            const SceneObjectVertexArray& v_property_array = pMesh->GetVertexPropertyArray(i);

            [m_pRenderer createVertexBuffer:v_property_array];
        }

        // -- For index --
        // const SceneObjectIndexArray& index_array = pMesh->GetIndexArray(0);
        
        MTLPrimitiveType mode;
        switch(pMesh->GetPrimitiveType())
        {
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
        for (decltype(indexGroupCount) i = 0; i < indexGroupCount; i++)
        {
            const SceneObjectIndexArray& index_array = pMesh->GetIndexArray(i);
            [m_pRenderer createIndexBuffer:index_array];

            MTLIndexType type;
            switch(index_array.GetIndexType())
            {
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
            
            size_t material_index = index_array.GetMaterialIndex();
            std::string material_key = pGeometryNode->GetMaterialRef(material_index);
            auto material = scene.GetMaterial(material_key);
            
            auto dbc = make_shared<MtlDrawBatchContext>();
            int32_t texture_id = -1;
            if (material) {
                auto color = material->GetBaseColor();
                if (color.ValueMap) {
                    const Image& image = color.ValueMap->GetTextureImage();
                    texture_id = [m_pRenderer createTexture:image];
                    dbc->m_diffuseColor = Vector3f(-1.0f);
                } else {
                    dbc->m_diffuseColor = color.Value.rgb;
                }
                color = material->GetSpecularColor();
                dbc->m_specularColor = color.Value.rgb;
                Parameter param = material->GetSpecularPower();
                dbc->m_specularPower = param.Value;
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
            [m_pRenderer getPBC].emplace_back(dbc);
        }
        
        v_property_offset += vertexPropertiesCount;
    }
}
