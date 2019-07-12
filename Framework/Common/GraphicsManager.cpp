#include <iostream>
#include "GraphicsManager.hpp"
#include "SceneManager.hpp"
#include "IApplication.hpp"
#include "SceneManager.hpp"
#include "IPhysicsManager.hpp"

using namespace newbieGE;
using namespace std;

int GraphicsManager::Initialize()
{
    int result = 0;
    InitConstants();
    return result;
}

void GraphicsManager::Finalize()
{
}

void GraphicsManager::Tick()
{
    if (g_pSceneManager->IsSceneChanged())
    {
        cout << "Detected Scene Change, reinitialize Graphics Manager..." << endl;
        Finalize();
        Initialize();
        g_pSceneManager->NotifySceneIsRenderingQueued();
    }
    // Generate the view matrix based on the camera's position.
    CalculateCameraMatrix();
    CalculateLights();

    UpdateConstants();

    SetPerFrameConstants();
    SetPerBatchConstants();
}

void GraphicsManager::UpdateConstants()
{
    for (auto pbc : m_DrawBatchContext)
    {
        if (void *rigidBody = pbc->node->RigidBody())
        {
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
        else
        {
            pbc->m_objectLocalMatrix = *pbc->node->GetCalculatedTransform();
        }
    }
}

void GraphicsManager::InitConstants()
{
    // Initialize the world/model matrix to the identity matrix.
    BuildIdentityMatrix(m_DrawFrameContext.m_worldMatrix);
}

void GraphicsManager::CalculateCameraMatrix()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        m_DrawFrameContext.m_viewMatrix = *pCameraNode->GetCalculatedTransform();
        InverseMatrix4X4f(m_DrawFrameContext.m_viewMatrix);
    }
    else
    {
        // use default build-in camera
        Vector3f position = {0, -5, 0}, lookAt = {0, 0, 0}, up = {0, 0, 1};
        BuildViewMatrix(m_DrawFrameContext.m_viewMatrix, position, lookAt, up);
    }

    float fieldOfView = PI / 2.0f;
    float nearClipDistance = 1.0f;
    float farClipDistance = 100.0f;

    if (pCameraNode)
    {
        auto pCamera = scene.GetCamera(pCameraNode->GetSceneObjectRef());
        // Set the field of view and screen aspect ratio.
        fieldOfView = dynamic_pointer_cast<SceneObjectPerspectiveCamera>(pCamera)->GetFov();
        nearClipDistance = pCamera->GetNearClipDistance();
        farClipDistance = pCamera->GetFarClipDistance();
    }

    const GfxConfiguration &conf = g_pApp->GetConfiguration();

    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;

    // Build the perspective projection matrix.
    BuildPerspectiveFovRHMatrix(m_DrawFrameContext.m_projectionMatrix, fieldOfView, screenAspect, nearClipDistance, farClipDistance);
}

void GraphicsManager::CalculateLights()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pLightNode = scene.GetFirstLightNode();
    if (pLightNode)
    {
        m_DrawFrameContext.m_lightPosition = {300.0f, 400.0f, 600.0f};
        TransformCoord(m_DrawFrameContext.m_lightPosition, *pLightNode->GetCalculatedTransform());

        auto pLight = scene.GetLight(pLightNode->GetSceneObjectRef());
        if (pLight)
        {
            m_DrawFrameContext.m_lightColor = pLight->GetColor().Value;
        }
    }
    else
    {
        // use default build-in light
        m_DrawFrameContext.m_lightPosition = {600.0f, -500.0f, 40.0f};
        m_DrawFrameContext.m_lightColor = {1.0f, 1.0f, 1.0f, 1.0f};
    }
}

void GraphicsManager::InitializeBuffers()
{
    cout << "[RHI] GraphicsManager::InitializeBuffers()" << endl;
}

void GraphicsManager::RenderBuffers()
{
    cout << "[RHI] GraphicsManager::RenderBuffers()" << endl;
}
