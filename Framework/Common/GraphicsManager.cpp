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
        EndScene();
        cout << "Detected Scene Change, reinitialize Graphics Manager..." << endl;
        const Scene &scene = g_pSceneManager->GetSceneForRendering();
        BeginScene(scene);
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
            Matrix4X4f trans;
            BuildIdentityMatrix(trans);

            // the geometry has rigid body bounded, we blend the simlation result here.
            Matrix4X4f simulated_result = g_pPhysicsManager->GetRigidBodyTransform(rigidBody);

            // apply the rotation part of the simlation result
            memcpy(trans[0], simulated_result[0], sizeof(float) * 3);
            memcpy(trans[1], simulated_result[1], sizeof(float) * 3);
            memcpy(trans[2], simulated_result[2], sizeof(float) * 3);

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
    m_DEBUG_showFlag = false;
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
        m_DrawFrameContext.m_lightPosition = {0.0f, 0.0f, 0.0f};
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
        m_DrawFrameContext.m_lightPosition = {-1.0f, -5.0f, 0.0f};
        m_DrawFrameContext.m_lightColor = {1.0f, 1.0f, 1.0f, 1.0f};
    }
}

void GraphicsManager::RenderBuffers()
{
    BeginFrame();
    BeginPass();
    DrawBatch(m_DrawBatchContext);
    EndPass();
    
#ifdef DEBUG
    if (m_DEBUG_showFlag)
    {
        BeginPass();
        DEBUG_DrawLines();
        EndPass();
    }
#endif
    
    EndFrame();
}

void GraphicsManager::BeginScene(const Scene &scene)
{
    //    for (auto pPass : m_InitPasses)
    //    {
    //        BeginCompute();
    //        pPass->Dispatch();
    //        EndCompute();
    //    }
}

#ifdef DEBUG
void GraphicsManager::DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    m_DEBUG_LineParams.push_back({from, to, color});
}
void GraphicsManager::DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    // TODO: Implement box using lines
    m_DEBUG_LineParams.push_back({bbMin, bbMax, color});
}

void GraphicsManager::DEBUG_ClearDebugBuffers()
{
    m_DEBUG_LineParams.clear();
    m_DEBUG_showFlag = false;
}

void GraphicsManager::DEBUG_DrawLines()
{
    for (DEBUG_LineParam lineParam : m_DEBUG_LineParams)
    {
        cout << "[GraphicsManager] GraphicsManager::DEBUG_DrawLine(" << lineParam.from << ","
             << lineParam.to << ","
             << lineParam.color << ")" << endl;
    }
}

#endif
