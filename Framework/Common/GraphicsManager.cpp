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
    m_DEBUG_Batches.emplace_back(DEBUG_DrawBatch());
    BuildIdentityMatrix(m_DEBUG_Batches[0].pbc.modelMatrix);
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
        m_DrawFrameContext.m_lightPosition = {0.0f, 0.0f, 0.0f, 1.0f};
        Transform(m_DrawFrameContext.m_lightPosition, *pLightNode->GetCalculatedTransform());

        auto pLight = scene.GetLight(pLightNode->GetSceneObjectRef());
        if (pLight)
        {
            m_DrawFrameContext.m_lightColor = pLight->GetColor().Value;
        }
    }
    else
    {
        // use default build-in light
        m_DrawFrameContext.m_lightPosition = {-1.0f, -5.0f, 0.0f, 1.0f};
        m_DrawFrameContext.m_lightColor = {1.0f, 1.0f, 1.0f, 1.0f};
    }
}

void GraphicsManager::RenderBuffers()
{
    BeginFrame();

    BeginPass();
    DrawBatch(m_DrawBatchContext);
#ifdef DEBUG
    if (m_DEBUG_showFlag)
    {
        DEBUG_DrawDebug();
    }
#endif
    EndPass();
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
void GraphicsManager::DEBUG_SetDrawPointParam(const Point3 &point, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    m_DEBUG_Batches[0].pointParams.push_back({point, color});
}

void GraphicsManager::DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    for (auto pt : point_set)
    {
        m_DEBUG_Batches[0].pointParams.push_back({*pt, color});
    }
}

void GraphicsManager::DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color, DEBUG_DrawBatch &batch)
{
    m_DEBUG_showFlag = true;
    for (auto pt : point_set)
    {
        batch.pointParams.push_back({*pt, color});
    }
}

void GraphicsManager::DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    m_DEBUG_Batches[0].lineParams.push_back({{from, color}, {to, color}});
}

void GraphicsManager::DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color, DEBUG_DrawBatch &batch)
{
    m_DEBUG_showFlag = true;
    batch.lineParams.push_back({{from, color}, {to, color}});
}

void GraphicsManager::DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color)
{
    auto count = vertices.size();
    assert(count >= 3);

    m_DEBUG_showFlag = true;

    for (auto i = 0; i < vertices.size(); i += 3)
    {
        m_DEBUG_Batches[0].triParams.push_back({{*vertices[i], color}, {*vertices[i + 1], color}, {*vertices[i + 2], color}});
    }
}

void GraphicsManager::DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color, DEBUG_DrawBatch &batch)
{
    auto count = vertices.size();
    assert(count >= 3);

    m_DEBUG_showFlag = true;

    for (auto i = 0; i < vertices.size(); i += 3)
    {
        batch.triParams.push_back({{*vertices[i], color}, {*vertices[i + 1], color}, {*vertices[i + 2], color}});
    }
}

void GraphicsManager::DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color)
{
    PointSet vertices;
    for (auto pEdge : face.Edges)
    {
        DEBUG_SetDrawLineParam(*pEdge->first, *pEdge->second, color);
        vertices.insert({pEdge->first, pEdge->second});
    }
    DEBUG_SetDrawPointSetParam(vertices, {1.0f});

    DEBUG_SetDrawTriangleParam(face.GetVertices(), {color.r / 2.0f, color.g / 2.0f, color.b / 2.0f});
}

void GraphicsManager::DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color, DEBUG_DrawBatch &batch)
{
    PointSet vertices;
    for (auto pEdge : face.Edges)
    {
        DEBUG_SetDrawLineParam(*pEdge->first, *pEdge->second, color, batch);
        vertices.insert({pEdge->first, pEdge->second});
    }
    DEBUG_SetDrawPointSetParam(vertices, {1.0f}, batch);

    DEBUG_SetDrawTriangleParam(face.GetVertices(), {color.r / 2.0f, color.g / 2.0f, color.b / 2.0f}, batch);
}

void GraphicsManager::DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Vector3f &color)
{
    for (auto pFace : polyhedron.Faces)
    {
        DEBUG_SetDrawPolygonParam(*pFace, color);
    }
}

void GraphicsManager::DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Matrix4X4f &trans, const Vector3f &color)
{
    DEBUG_DrawBatch newDrawBatch;
    newDrawBatch.pbc.modelMatrix = trans;

    for (auto pFace : polyhedron.Faces)
    {
        DEBUG_SetDrawPolygonParam(*pFace, color, newDrawBatch);
    }
    m_DEBUG_Batches.emplace_back(newDrawBatch);
}

void GraphicsManager::DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color)
{
    m_DEBUG_showFlag = true;
    // 12 lines
    m_DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMin.x, bbMin.y, bbMax.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMin.x, bbMax.y, bbMin.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMax.x, bbMin.y, bbMin.z, 1.0f}, color}});

    m_DEBUG_Batches[0].lineParams.push_back({{{bbMin.x, bbMax.y, bbMax.z, 1.0f}, color}, {{bbMin.x, bbMax.y, bbMin.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMin.x, bbMax.y, bbMax.z, 1.0f}, color}, {{bbMin.x, bbMin.y, bbMax.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMin.x, bbMax.y, bbMax.z, 1.0f}, color}, {{bbMax.x, bbMax.y, bbMax.z, 1.0f}, color}});

    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMin.y, bbMax.z, 1.0f}, color}, {{bbMax.x, bbMin.y, bbMin.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMin.y, bbMax.z, 1.0f}, color}, {{bbMax.x, bbMax.y, bbMax.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMin.y, bbMax.z, 1.0f}, color}, {{bbMin.x, bbMin.y, bbMax.z, 1.0f}, color}});

    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMax.y, bbMin.z, 1.0f}, color}, {{bbMax.x, bbMax.y, bbMax.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMax.y, bbMin.z, 1.0f}, color}, {{bbMax.x, bbMin.y, bbMin.z, 1.0f}, color}});
    m_DEBUG_Batches[0].lineParams.push_back({{{bbMax.x, bbMax.y, bbMin.z, 1.0f}, color}, {{bbMin.x, bbMax.y, bbMin.z, 1.0f}, color}});
}

void GraphicsManager::DEBUG_ClearDebugBuffers()
{
    m_DEBUG_Batches.clear();
    m_DEBUG_Batches.emplace_back(DEBUG_DrawBatch());
    BuildIdentityMatrix(m_DEBUG_Batches[0].pbc.modelMatrix);
    m_DEBUG_showFlag = false;
}

void GraphicsManager::DEBUG_DrawDebug()
{
    cout << "[GraphicsManager] GraphicsManager::DEBUG_DrawDebug" << endl;
    long idx = 0;
    for (auto batch : m_DEBUG_Batches)
    {
        cout << "Batch id: " << idx << endl;
        ++idx;

        // Points
        for (DEBUG_PointParam pointParam : batch.pointParams)
        {
            cout << "Points(" << pointParam.pos << "," << pointParam.color << ")" << endl;
        }
        // Lines
        for (DEBUG_LineParam lineParam : batch.lineParams)
        {
            cout << "Lines(" << lineParam.from.pos << ","
                 << lineParam.from.color << "), ("
                 << lineParam.to.pos << ", " << lineParam.to.color
                 << ")" << endl;
        }
        // Triangles
        for (DEBUG_TriangleParam triParam : batch.triParams)
        {
            cout << "Triangles(" << triParam.v0.pos << ","
                 << triParam.v1.pos << ","
                 << triParam.v2.pos << ","
                 << triParam.v0.color << ")" << endl;
        }
    }
}

#endif
