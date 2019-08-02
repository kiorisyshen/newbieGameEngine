#include "GraphicsManager.hpp"
#include <iostream>
#include "ForwardRenderPass.hpp"
#include "IApplication.hpp"
#include "IPhysicsManager.hpp"
#include "SceneManager.hpp"

using namespace newbieGE;
using namespace std;

int GraphicsManager::Initialize() {
    int result = 0;

    m_Frames.resize(GfxConfiguration::kMaxInFlightFrameCount);
    for (auto &frame : m_Frames) {
        BuildIdentityMatrix(frame.frameContext.worldMatrix);
    }

#ifdef DEBUG
    m_DEBUG_showFlag = false;
    for (auto &frame : m_Frames) {
        frame.DEBUG_Batches.emplace_back(DEBUG_DrawBatch());
        BuildIdentityMatrix(frame.DEBUG_Batches[0].pbc.modelMatrix);
    }
#endif

    m_DrawPasses.push_back(make_shared<ForwardRenderPass>());

    bool initShaderSucc = InitializeShaders();
    if (!initShaderSucc) result = -1;

    return result;
}

void GraphicsManager::Finalize() {
#ifdef DEBUG
    DEBUG_ClearDebugBuffers();
#endif
    EndScene();
}

void GraphicsManager::Tick() {
    if (g_pSceneManager->IsSceneChanged()) {
        EndScene();
        cout << "[GraphicsManager] Detected Scene Change, reinitialize Graphics Manager..." << endl;
        const Scene &scene = g_pSceneManager->GetSceneForRendering();
        BeginScene(scene);
        g_pSceneManager->NotifySceneIsRenderingQueued();
    }
    // Generate the view matrix based on the camera's position.
    CalculateCameraMatrix();
    CalculateLights();

    UpdateConstants();

    auto &frame = m_Frames[m_nFrameIndex];

    SetPerFrameConstants(frame.frameContext);
    SetPerBatchConstants(frame.batchContext);
    SetLightInfo(frame.lightInfo);
}

void GraphicsManager::UpdateConstants() {
    // update scene object position
    auto &frame = m_Frames[m_nFrameIndex];

    for (auto pbc : frame.batchContext) {
        if (void *rigidBody = pbc->node->RigidBody()) {
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

            pbc->objectLocalMatrix = trans;
        } else {
            pbc->objectLocalMatrix = *pbc->node->GetCalculatedTransform();
        }
    }
}

void GraphicsManager::CalculateCameraMatrix() {
    auto &scene                    = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode               = scene.GetFirstCameraNode();
    DrawFrameContext &frameContext = m_Frames[m_nFrameIndex].frameContext;

    if (pCameraNode) {
        frameContext.viewMatrix = *pCameraNode->GetCalculatedTransform();
        InverseMatrix4X4f(frameContext.viewMatrix);
    } else {
        // use default build-in camera
        Vector3f position = {0, -5, 0}, lookAt = {0, 0, 0}, up = {0, 0, 1};
        BuildViewMatrix(frameContext.viewMatrix, position, lookAt, up);
    }

    float fieldOfView      = PI / 2.0f;
    float nearClipDistance = 1.0f;
    float farClipDistance  = 100.0f;

    if (pCameraNode) {
        auto pCamera = scene.GetCamera(pCameraNode->GetSceneObjectRef());
        // Set the field of view and screen aspect ratio.
        fieldOfView      = dynamic_pointer_cast<SceneObjectPerspectiveCamera>(pCamera)->GetFov();
        nearClipDistance = pCamera->GetNearClipDistance();
        farClipDistance  = pCamera->GetFarClipDistance();
    }

    const GfxConfiguration &conf = g_pApp->GetConfiguration();

    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;

    // Build the perspective projection matrix.
    BuildPerspectiveFovRHMatrix(frameContext.projectionMatrix, fieldOfView, screenAspect, nearClipDistance,
                                farClipDistance);
}

void GraphicsManager::CalculateLights() {
    DrawFrameContext &frameContext = m_Frames[m_nFrameIndex].frameContext;
    LightInfo &light_info          = m_Frames[m_nFrameIndex].lightInfo;

    frameContext.ambientColor = {0.01f, 0.01f, 0.01f, 1.0f};
    frameContext.numLights    = 0;

    auto &scene = g_pSceneManager->GetSceneForRendering();
    for (auto LightNode : scene.LightNodes) {
        auto pLightNode = LightNode.second.lock();
        // No light will be added. (Or we could add a default light)
        if (!pLightNode) continue;

        Light &light = light_info.lights[frameContext.numLights];

        auto trans_ptr      = pLightNode->GetCalculatedTransform();
        light.lightPosition = {0.0f, 0.0f, 0.0f, 1.0f};
        Transform(light.lightPosition, *trans_ptr);
        light.lightDirection = {0.0f, 0.0f, -1.0f, 0.0f};
        Transform(light.lightDirection, *trans_ptr);

        auto pLight = scene.GetLight(pLightNode->GetSceneObjectRef());
        if (pLight) {
            light.lightColor              = pLight->GetColor().Value;
            light.lightIntensity          = pLight->GetIntensity();
            const AttenCurve &atten_curve = pLight->GetDistanceAttenuation();
            light.lightDistAttenCurveType = (int32_t)atten_curve.type;
            memcpy(light.lightDistAttenCurveParams, &atten_curve.u, sizeof(atten_curve.u));

            if (pLight->GetType() == SceneObjectType::kSceneObjectTypeLightInfi) {
                light.lightType        = (int32_t)LightType::Infinity;
                light.lightPosition[3] = 0.0f;
            } else if (pLight->GetType() == SceneObjectType::kSceneObjectTypeLightSpot) {
                auto plight                         = dynamic_pointer_cast<SceneObjectSpotLight>(pLight);
                const AttenCurve &angle_atten_curve = plight->GetAngleAttenuation();
                light.lightType                     = (int32_t)LightType::Spot;
                light.lightAngleAttenCurveType      = (int32_t)angle_atten_curve.type;
                memcpy(light.lightAngleAttenCurveParams, &angle_atten_curve.u, sizeof(angle_atten_curve.u));
            } else if (pLight->GetType() == SceneObjectType::kSceneObjectTypeLightArea) {
                auto plight     = dynamic_pointer_cast<SceneObjectAreaLight>(pLight);
                light.lightType = (int32_t)LightType::Area;
                light.lightSize = plight->GetDimension();
            } else {
                light.lightType = (int32_t)LightType::Omni;
            }

            ++frameContext.numLights;
        } else {
            assert(0);
        }
    }
}

void GraphicsManager::RenderBuffers() {
    BeginFrame();

    auto &frame = m_Frames[m_nFrameIndex];
    for (auto &pDrawPass : m_DrawPasses) {
        BeginPass(pDrawPass->GetPassIndex());
        pDrawPass->Draw(frame);
        EndPass(pDrawPass->GetPassIndex());
    }

    EndFrame();
}

void GraphicsManager::BeginScene(const Scene &scene) {
    //    for (auto pPass : m_InitPasses)
    //    {
    //        BeginCompute();
    //        pPass->Dispatch();
    //        EndCompute();
    //    }
}

void GraphicsManager::EndScene() {
    m_Frames.clear();
    m_nFrameIndex = 0;
}

#ifdef DEBUG
bool GraphicsManager::DEBUG_IsShowDebug() {
    return m_DEBUG_showFlag;
}

void GraphicsManager::DEBUG_ToggleDebugInfo() {
    m_DEBUG_showFlag = !m_DEBUG_showFlag;
}

void GraphicsManager::DEBUG_SetDrawPointParam(const Point3 &point, const Vector3f &color) {
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].pointParams.push_back({point, color});
}

void GraphicsManager::DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color) {
    for (auto pt : point_set) {
        m_Frames[m_nFrameIndex].DEBUG_Batches[0].pointParams.push_back({*pt, color});
    }
}

void GraphicsManager::DEBUG_SetDrawPointSetParam(const PointSet &point_set, const Vector3f &color,
                                                 DEBUG_DrawBatch &batch) {
    for (auto pt : point_set) {
        batch.pointParams.push_back({*pt, color});
    }
}

void GraphicsManager::DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color) {
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back({{from, color}, {to, color}});
}

void GraphicsManager::DEBUG_SetDrawLineParam(const Vector3f &from, const Vector3f &to, const Vector3f &color,
                                             DEBUG_DrawBatch &batch) {
    batch.lineParams.push_back({{from, color}, {to, color}});
}

void GraphicsManager::DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color) {
    auto count = vertices.size();
    assert(count >= 3);

    for (auto i = 0; i < vertices.size(); i += 3) {
        m_Frames[m_nFrameIndex].DEBUG_Batches[0].triParams.push_back(
            {{*vertices[i], color}, {*vertices[i + 1], color}, {*vertices[i + 2], color}});
    }
}

void GraphicsManager::DEBUG_SetDrawTriangleParam(const PointList &vertices, const Vector3f &color,
                                                 DEBUG_DrawBatch &batch) {
    auto count = vertices.size();
    assert(count >= 3);

    for (auto i = 0; i < vertices.size(); i += 3) {
        batch.triParams.push_back({{*vertices[i], color}, {*vertices[i + 1], color}, {*vertices[i + 2], color}});
    }
}

void GraphicsManager::DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color) {
    PointSet vertices;
    for (auto pEdge : face.Edges) {
        DEBUG_SetDrawLineParam(*pEdge->first, *pEdge->second, color);
        vertices.insert({pEdge->first, pEdge->second});
    }
    DEBUG_SetDrawPointSetParam(vertices, color);

    DEBUG_SetDrawTriangleParam(face.GetVertices(), {color[0] / 2.0f, color[1] / 2.0f, color[2] / 2.0f});
}

void GraphicsManager::DEBUG_SetDrawPolygonParam(const Face &face, const Vector3f &color, DEBUG_DrawBatch &batch) {
    PointSet vertices;
    for (auto pEdge : face.Edges) {
        DEBUG_SetDrawLineParam(*pEdge->first, *pEdge->second, color, batch);
        vertices.insert({pEdge->first, pEdge->second});
    }
    DEBUG_SetDrawPointSetParam(vertices, color, batch);

    DEBUG_SetDrawTriangleParam(face.GetVertices(), {color[0] / 2.0f, color[1] / 2.0f, color[2] / 2.0f}, batch);
}

void GraphicsManager::DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Vector3f &color) {
    for (auto pFace : polyhedron.Faces) {
        DEBUG_SetDrawPolygonParam(*pFace, color);
    }
}

void GraphicsManager::DEBUG_SetDrawPolyhydronParam(const Polyhedron &polyhedron, const Matrix4X4f &trans, const Vector3f &color) {
    DEBUG_DrawBatch newDrawBatch;
    newDrawBatch.pbc.modelMatrix = trans;

    for (auto pFace : polyhedron.Faces) {
        DEBUG_SetDrawPolygonParam(*pFace, color, newDrawBatch);
    }
    m_Frames[m_nFrameIndex].DEBUG_Batches.emplace_back(newDrawBatch);
}

void GraphicsManager::DEBUG_SetDrawBoxParam(const Vector3f &bbMin, const Vector3f &bbMax, const Vector3f &color) {
    // 12 lines
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMin[0], bbMin[1], bbMax[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMin[0], bbMax[1], bbMin[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back({{bbMin, color}, {{bbMax[0], bbMin[1], bbMin[2], 1.0f}, color}});

    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMin[0], bbMax[1], bbMax[2], 1.0f}, color}, {{bbMin[0], bbMax[1], bbMin[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMin[0], bbMax[1], bbMax[2], 1.0f}, color}, {{bbMin[0], bbMin[1], bbMax[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMin[0], bbMax[1], bbMax[2], 1.0f}, color}, {{bbMax[0], bbMax[1], bbMax[2], 1.0f}, color}});

    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMin[1], bbMax[2], 1.0f}, color}, {{bbMax[0], bbMin[1], bbMin[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMin[1], bbMax[2], 1.0f}, color}, {{bbMax[0], bbMax[1], bbMax[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMin[1], bbMax[2], 1.0f}, color}, {{bbMin[0], bbMin[1], bbMax[2], 1.0f}, color}});

    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMax[1], bbMin[2], 1.0f}, color}, {{bbMax[0], bbMax[1], bbMax[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMax[1], bbMin[2], 1.0f}, color}, {{bbMax[0], bbMin[1], bbMin[2], 1.0f}, color}});
    m_Frames[m_nFrameIndex].DEBUG_Batches[0].lineParams.push_back(
        {{{bbMax[0], bbMax[1], bbMin[2], 1.0f}, color}, {{bbMin[0], bbMax[1], bbMin[2], 1.0f}, color}});
}

void GraphicsManager::DEBUG_ClearDebugBuffers() {
    m_Frames[m_nFrameIndex].DEBUG_Batches.clear();
    m_Frames[m_nFrameIndex].DEBUG_Batches.emplace_back(DEBUG_DrawBatch());
    BuildIdentityMatrix(m_Frames[m_nFrameIndex].DEBUG_Batches[0].pbc.modelMatrix);
}

// void GraphicsManager::DEBUG_DrawDebug()
// {
//     cout << "[GraphicsManager] GraphicsManager::DEBUG_DrawDebug" << endl;
//     long idx = 0;
//     for (auto batch : m_Frames[m_nFrameIndex].DEBUG_Batches) {
//         cout << "Batch id: " << idx << endl;
//         ++idx;

//         // Points
//         for (DEBUG_PointParam pointParam : batch.pointParams) {
//             cout << "Points(" << pointParam.pos << "," << pointParam.color << ")" << endl;
//         }
//         // Lines
//         for (DEBUG_LineParam lineParam : batch.lineParams) {
//             cout << "Lines(" << lineParam.from.pos << "," << lineParam.from.color << "), (" << lineParam.to.pos << ", "
//                  << lineParam.to.color << ")" << endl;
//         }
//         // Triangles
//         for (DEBUG_TriangleParam triParam : batch.triParams) {
//             cout << "Triangles(" << triParam.v0.pos << "," << triParam.v1.pos << "," << triParam.v2.pos << ","
//                  << triParam.v0.color << ")" << endl;
//         }
//     }
// }

#endif
