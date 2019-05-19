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
    BuildIdentityMatrix(m_worldMatrix);

    // Set the field of view and screen aspect ratio.
    float fieldOfView = PI / 4.0f;
    const GfxConfiguration& conf = g_pApp->GetConfiguration();

    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;

    // Build the perspective projection matrix.
    BuildPerspectiveFovLHMatrix(m_projectionMatrix, fieldOfView, screenAspect, screenNear, screenDepth);
    
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
    MatrixRotationY(rotationMatrixY, rotateAngle);
    MatrixRotationZ(rotationMatrixZ, rotateAngle);
    MatrixMultiply(m_worldMatrix, rotationMatrixZ, rotationMatrixY);

    // Generate the view matrix based on the camera's position.
    CalculateCameraPosition();

    // Set the color shader as the current shader program and set the matrices that it will use for rendering.
//    [m_pRenderer loadMetal];
    SetShaderParameters(&m_worldMatrix, &m_viewMatrix, &m_projectionMatrix);

    [m_pRenderer tick];
}

bool MetalGraphicsManager::SetShaderParameters(Matrix4X4f* worldMatrix, Matrix4X4f* viewMatrix, Matrix4X4f* projectionMatrix)
{
    [m_pRenderer setShaderWorldM:worldMatrix viewM:viewMatrix projectionM:projectionMatrix];
    return true;
}

void MetalGraphicsManager::InitializeBuffers()
{
    auto& scene = g_pSceneManager->GetSceneForRendering();
    auto pGeometry = scene.GetFirstGeometry();

    uint32_t batch_index = 0;
    uint32_t v_property_offset = 0;
    uint32_t index_offset = 0;

    while (pGeometry)
    {
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
        std::vector<std::shared_ptr<MtlDrawBatchContext> >& VAO_ref = [m_pRenderer getVAO];
        VAO_ref.push_back(dbc);

        pGeometry = scene.GetNextGeometry();
    }
}

void MetalGraphicsManager::RenderBuffers()
{
    
}

void MetalGraphicsManager::CalculateCameraPosition()
{
    Vector3f up, position, lookAt;
    float yaw, pitch, roll;
    Matrix4X4f rotationMatrix;


    // Setup the vector that points upwards.
    up.x = 0.0f;
    up.y = 1.0f;
    up.z = 0.0f;

    // Setup the position of the camera in the world.
    position.x = m_positionX;
    position.y = m_positionY;
    position.z = m_positionZ;

    // Setup where the camera is looking by default.
    lookAt.x = 0.0f;
    lookAt.y = 0.0f;
    lookAt.z = 1.0f;

    // Set the yaw (Y axis), pitch (X axis), and roll (Z axis) rotations in radians.
    pitch = m_rotationX * 0.0174532925f;
    yaw   = m_rotationY * 0.0174532925f;
    roll  = m_rotationZ * 0.0174532925f;

    // Create the rotation matrix from the yaw, pitch, and roll values.
    MatrixRotationYawPitchRoll(rotationMatrix, yaw, pitch, roll);

    // Transform the lookAt and up vector by the rotation matrix so the view is correctly rotated at the origin.
    TransformCoord(lookAt, rotationMatrix);
    TransformCoord(up, rotationMatrix);

    // Translate the rotated camera position to the location of the viewer.
    lookAt.x = position.x + lookAt.x;
    lookAt.y = position.y + lookAt.y;
    lookAt.z = position.z + lookAt.z;

    // Finally create the view matrix from the three updated vectors.
    BuildViewMatrix(m_viewMatrix, position, lookAt, up);
}

bool MetalGraphicsManager::InitializeShader(const char* vsFilename, const char* fsFilename)
{
    return true;
}
