#include <iostream>
#include "GraphicsManager.hpp"
#include "SceneManager.hpp"
#include "cbuffer.h"
#include "IApplication.hpp"
#include "SceneManager.hpp"

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

    Clear();
    Draw();
}

void GraphicsManager::Clear()
{
}

void GraphicsManager::Draw()
{
}

bool GraphicsManager::SetPerFrameShaderParameters()
{
    cout << "[RHI] GraphicsManager::SetPerFrameShaderParameters(void)" << endl;
    return true;
}

void GraphicsManager::InitConstants()
{
    // Initialize the world/model matrix to the identity matrix.
    BuildIdentityMatrix(m_DrawFrameContext.m_worldMatrix);
}

void GraphicsManager::CalculateCameraMatrix()
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

void GraphicsManager::CalculateLights()
{
    auto& scene = g_pSceneManager->GetSceneForRendering();
    auto pLightNode = scene.GetFirstLightNode();
    if (pLightNode) {
        m_DrawFrameContext.m_lightPosition = { 300.0f, 400.0f, 600.0f };
        TransformCoord(m_DrawFrameContext.m_lightPosition, *pLightNode->GetCalculatedTransform());

        auto pLight = scene.GetLight(pLightNode->GetSceneObjectRef());
        if (pLight) {
            m_DrawFrameContext.m_lightColor = pLight->GetColor().Value;
        }
    }
    else {
        // use default build-in light 
        m_DrawFrameContext.m_lightPosition = { 600.0f, -500.0f, 40.0f};
        m_DrawFrameContext.m_lightColor = { 1.0f, 1.0f, 1.0f, 1.0f };
    }
}

void GraphicsManager::InitializeBuffers()
{
}

void GraphicsManager::RenderBuffers()
{
    cout << "[RHI] GraphicsManager::RenderBuffers()" << endl;
}

void GraphicsManager::WorldRotateX(float radians)
{
    Matrix4X4f rotationMatrix;
    MatrixRotationX(rotationMatrix, radians);
    m_DrawFrameContext.m_worldMatrix = m_DrawFrameContext.m_worldMatrix * rotationMatrix;
}

void GraphicsManager::WorldRotateY(float radians)
{
    Matrix4X4f rotationMatrix;
    MatrixRotationY(rotationMatrix, radians);
    m_DrawFrameContext.m_worldMatrix = m_DrawFrameContext.m_worldMatrix * rotationMatrix;
}

