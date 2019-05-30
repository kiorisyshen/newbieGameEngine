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
    // Initialize the world/model matrix to the identity matrix.
    BuildIdentityMatrix(m_DrawFrameContext.m_worldMatrix);

    InitializeBuffers();
    
    return 0;
}

void MetalGraphicsManager::Finalize()
{
    [m_pRenderer Finalize];
}

void MetalGraphicsManager::Tick()
{
    Draw();
}

void MetalGraphicsManager::Clear()
{
    
}

void MetalGraphicsManager::Draw()
{
    static float rotateAngle = 0.0f;

    // Update world matrix to rotate the model
    rotateAngle += PI / 120;
    Matrix4X4f rotationMatrixY;
    Matrix4X4f rotationMatrixZ;
    //MatrixRotationY(rotationMatrixY, rotateAngle);
    MatrixRotationZ(rotationMatrixZ, rotateAngle);
    //MatrixMultiply(m_DrawFrameContext.m_worldMatrix, rotationMatrixZ, rotationMatrixY);
    m_DrawFrameContext.m_worldMatrix = rotationMatrixZ;

    // Generate the view matrix based on the camera's position.
    CalculateCameraPosition();
    CalculateLights();

    // Set the color shader as the current shader program and set the matrices that it will use for rendering.
    SetShaderParameters();

    [m_pRenderer tick];
}

bool MetalGraphicsManager::SetShaderParameters()
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

void MetalGraphicsManager::CalculateCameraPosition()
{
    auto& scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode) {
        m_DrawFrameContext.m_viewMatrix = *pCameraNode->GetCalculatedTransform();
        InverseMatrix4X4f(m_DrawFrameContext.m_viewMatrix);
    }
    else {
        // use default build-in camera
        Vector3f position = { 0, -5, 0 }, lookAt = { 0, 0, 0 }, up = { 0, 0, 1 };
        BuildViewMatrix(m_DrawFrameContext.m_viewMatrix, position, lookAt, up);
    }
    
    float fieldOfView = PI / 2.0f;
    float nearClipDistance = 1.0f;
    float farClipDistance = 100.0f;
    
    if (pCameraNode) {
        auto pCamera = scene.GetCamera(pCameraNode->GetSceneObjectRef());
        // Set the field of view and screen aspect ratio.
        fieldOfView = dynamic_pointer_cast<SceneObjectPerspectiveCamera>(pCamera)->GetFov();
        nearClipDistance = pCamera->GetNearClipDistance();
        farClipDistance = pCamera->GetFarClipDistance();
    }
    
    const GfxConfiguration& conf = g_pApp->GetConfiguration();
    
    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;
    
    // Build the perspective projection matrix.
    BuildPerspectiveFovRHMatrix(m_DrawFrameContext.m_projectionMatrix, fieldOfView, screenAspect, nearClipDistance, farClipDistance);
}

void MetalGraphicsManager::CalculateLights()
{
    auto& scene = g_pSceneManager->GetSceneForRendering();
    auto pLightNode = scene.GetFirstLightNode();
    if (pLightNode) {
        m_DrawFrameContext.m_lightPosition = { 0.0f, 0.0f, 0.0f };
        TransformCoord(m_DrawFrameContext.m_lightPosition, *pLightNode->GetCalculatedTransform());
        
        auto pLight = scene.GetLight(pLightNode->GetSceneObjectRef());
        if (pLight) {
            m_DrawFrameContext.m_lightColor = pLight->GetColor().Value;
        }
    }
    else {
        // use default build-in light
        //  z ^  y
        //    | /
        //    |---> x
        m_DrawFrameContext.m_lightPosition = { 600.0f, -500.0f, 40.0f};   // x, y, z
        m_DrawFrameContext.m_lightColor = { 1.0f, 1.0f, 1.0f, 1.0f };   // A, R, G, B
    }
}

bool MetalGraphicsManager::InitializeShader(const char* vsFilename, const char* fsFilename)
{
    return true;
}
