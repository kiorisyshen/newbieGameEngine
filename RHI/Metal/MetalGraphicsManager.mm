#include <iostream>
#include <fstream>
#include "MetalGraphicsManager.h"
#include "AssetLoader.hpp"
#include "IApplication.hpp"
#include "SceneManager.hpp"
#include "MetalRenderer.h"

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
     static float rotateAngle = 0.0f;

    // // Update world matrix to rotate the model
     rotateAngle += PI / 120;
     Matrix4X4f rotationMatrixZ;
     MatrixRotationZ(rotationMatrixZ, rotateAngle);
     m_DrawFrameContext.m_worldMatrix = rotationMatrixZ;
    
    // Set the color shader as the current shader program and set the matrices that it will use for rendering.
    SetPerFrameShaderParameters();

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
    auto pGeometryNode = scene.GetFirstGeometryNode(); 

    uint32_t batch_index = 0;
    uint32_t v_property_offset = 0;
    uint32_t index_offset = 0;

    while (pGeometryNode)
    {
        if (!pGeometryNode->Visible())
        {
            pGeometryNode = scene.GetNextGeometryNode();
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
            [m_pRenderer getPBC].emplace_back(dbc);
        }
        
        v_property_offset += vertexPropertiesCount;

        pGeometryNode = scene.GetNextGeometryNode();
    }
}
