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
//    [m_pRenderer loadMetal];
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
        auto pGeometry = scene.GetGeometry(pGeometryNode->GetSceneObjectRef());
        assert(pGeometry);
        auto pMesh = pGeometry->GetMesh().lock();
        if (!pMesh) return;

        // Set the number of vertex properties.
        auto vertexPropertiesCount = pMesh->GetVertexPropertiesCount();

        // Set the number of vertices in the vertex array.
        auto vertexCount = pMesh->GetVertexCount();

        for (decltype(vertexPropertiesCount) i = 0; i < vertexPropertiesCount; i++)
        {
            const SceneObjectVertexArray& v_property_array = pMesh->GetVertexPropertyArray(i);

            [m_pRenderer createVertexBuffer:v_property_array];
        }

        const SceneObjectIndexArray& index_array = pMesh->GetIndexArray(0);
            [m_pRenderer createIndexBuffer:index_array];

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

        // auto material_index = index_array.GetMaterialIndex();
        // auto material_key = pGeometryNode->GetMaterialRef(material_index);
        // auto material = scene.GetMaterial(material_key);

        auto dbc = make_shared<MtlDrawBatchContext>();
        dbc->batchIndex = batch_index++;
        dbc->index_offset = index_offset++;
        dbc->index_count = (uint32_t)index_array.GetIndexCount();
        dbc->index_mode = mode;
        dbc->index_type = type;
        dbc->property_offset = v_property_offset;
        dbc->property_count = vertexPropertiesCount;
        dbc->transform = pGeometryNode->GetCalculatedTransform();
        std::vector<std::shared_ptr<MtlDrawBatchContext> >& VAO_ref = [m_pRenderer getVAO];
        VAO_ref.push_back(dbc);

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
        Vector3f position = { 0, 0, 5 }, lookAt = { 0, 0, 0 }, up = { 0, 1, 0 };
        BuildViewMatrix(m_DrawFrameContext.m_viewMatrix, position, lookAt, up);
    }
    
    auto pCamera = scene.GetCamera(pCameraNode->GetSceneObjectRef());
    
    // Set the field of view and screen aspect ratio.
    float fieldOfView = dynamic_pointer_cast<SceneObjectPerspectiveCamera>(pCamera)->GetFov();
    const GfxConfiguration& conf = g_pApp->GetConfiguration();
    
    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;
    
    // Build the perspective projection matrix.
    BuildPerspectiveFovRHMatrix(m_DrawFrameContext.m_projectionMatrix, fieldOfView, screenAspect, pCamera->GetNearClipDistance(), pCamera->GetFarClipDistance());
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
        m_DrawFrameContext.m_lightPosition = { 10.0f, 10.0f, -10.0f};
        m_DrawFrameContext.m_lightColor = { 1.0f, 1.0f, 1.0f, 1.0f };
    }
}

bool MetalGraphicsManager::InitializeShader(const char* vsFilename, const char* fsFilename)
{
    return true;
}
