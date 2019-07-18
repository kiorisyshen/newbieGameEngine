#include <iostream>
#include <random>
#include "DebugInfo_logic.hpp"
#include "IApplication.hpp"
#include "GraphicsManager.hpp"
#include "SceneManager.hpp"
#include "IPhysicsManager.hpp"

using namespace newbieGE;
using namespace std;

int DebugInfo_logic::Initialize()
{
    int result;

    cout << "[GameLogic] Initialize" << endl;
    cout << "[GameLogic] Start Loading Game Scene" << endl;
    result = g_pSceneManager->LoadScene("Scene/Empty.ogex");

    // generate random point cloud
    default_random_engine generator;
    uniform_real_distribution<float> distribution(-3.0f, 3.0f);
    auto dice = std::bind(distribution, generator);

    int point_count = 30;
    if (g_pApp->GetCommandLineArgumentsCount() > 1)
        point_count = atoi(g_pApp->GetCommandLineArgument(1));

    for (auto i = 0; i < point_count; i++)
    {
        PointPtr point_ptr = make_shared<Point3>(dice(), dice(), dice());
        m_QuickHull.AddPoint(std::move(point_ptr));
    }

    return result;
}

void DebugInfo_logic::Finalize()
{
    cout << "[GameLogic] Finalize" << endl;
}

void DebugInfo_logic::Tick()
{
}

#ifdef DEBUG
void DebugInfo_logic::DrawDebugInfo()
{
    auto point_set = m_QuickHull.GetPointSet();
    auto hull = m_QuickHull.GetHull();

    // draw the hull
    g_pGraphicsManager->DEBUG_SetDrawPolyhydronParam(hull, Vector3f(0.9f, 0.5f, 0.5f));

    // draw the point cloud
    g_pGraphicsManager->DEBUG_SetDrawPointSetParam(point_set, Vector3f(0.7f));
}
#endif

void DebugInfo_logic::OnLeftKeyDown()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        auto local_axis = pCameraNode->GetLocalAxis();
        Vector3f camera_x_axis;
        memcpy(camera_x_axis.data, local_axis[0], sizeof(camera_x_axis));

        // move camera along its local axis x direction
        pCameraNode->MoveBy(camera_x_axis);
    }
}

void DebugInfo_logic::OnRightKeyDown()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        auto local_axis = pCameraNode->GetLocalAxis();
        Vector3f camera_x_axis;
        memcpy(camera_x_axis.data, local_axis[0], sizeof(camera_x_axis));

        // move along camera local axis -x direction
        pCameraNode->MoveBy(camera_x_axis * -1.0f);
    }
}

void DebugInfo_logic::OnUpKeyDown()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        auto local_axis = pCameraNode->GetLocalAxis();
        Vector3f camera_y_axis;
        memcpy(camera_y_axis.data, local_axis[1], sizeof(camera_y_axis));

        // move camera along its local axis y direction
        pCameraNode->MoveBy(camera_y_axis);
    }
}

void DebugInfo_logic::OnDownKeyDown()
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        auto local_axis = pCameraNode->GetLocalAxis();
        Vector3f camera_y_axis;
        memcpy(camera_y_axis.data, local_axis[1], sizeof(camera_y_axis));

        // move camera along its local axis -y direction
        pCameraNode->MoveBy(camera_y_axis * -1.0f);
    }
}

void DebugInfo_logic::OnButton1Down()
{
    static bool first_time = true;

    if (first_time)
    {
        m_QuickHull.Init();
        first_time = false;
    }

    m_QuickHull.Iterate();
}

void DebugInfo_logic::OnAnalogStick(int id, float deltaX, float deltaY)
{
    auto &scene = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode)
    {
        auto screen_width = g_pApp->GetConfiguration().screenWidth;
        auto screen_height = g_pApp->GetConfiguration().screenHeight;
        // move camera along its local axis -y direction
        pCameraNode->RotateBy(deltaX / screen_width * PI, deltaY / screen_height * PI, 0.0f);
    }
}
