#include "DebugManager.hpp"
#include <iostream>
#include "GraphicsManager.hpp"
#include "IGameLogic.hpp"
#include "IPhysicsManager.hpp"

using namespace newbieGE;
using namespace std;

#ifdef DEBUG
int DebugManager::Initialize()
{
    return 0;
}

void DebugManager::Finalize()
{
}

void DebugManager::Tick()
{
    if (m_bDrawDebugInfo) {
        g_pGraphicsManager->DEBUG_ClearDebugBuffers();
        DrawDebugInfo();
        g_pPhysicsManager->DrawDebugInfo();
        g_pGameLogic->DrawDebugInfo();
        g_pGraphicsManager->DEBUG_SetBuffer();
    }
}

void DebugManager::ToggleDebugInfo()
{
    m_bDrawDebugInfo = !m_bDrawDebugInfo;
    if (!m_bDrawDebugInfo) {
        g_pGraphicsManager->DEBUG_ClearDebugBuffers();
    }
}

void DebugManager::DrawDebugInfo()
{
    DrawGrid();
    DrawAxis();
}

void DebugManager::DrawAxis()
{
    // x - axis
    Vector3f from({-1000.0f, 0.0f, 0.0f});
    Vector3f to({1000.0f, 0.0f, 0.0f});
    Vector3f color({1.0f, 0.0f, 0.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);

    // y - axis
    from.Set({0.0f, -1000.0f, 0.0f});
    to.Set({0.0f, 1000.0f, 0.0f});
    color.Set({0.0f, 1.0f, 0.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);

    // z - axis
    from.Set({0.0f, 0.0f, -1000.0f});
    to.Set({0.0f, 0.0f, 1000.0f});
    color.Set({0.0f, 0.0f, 1.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);
}

void DebugManager::DrawGrid()
{
    Vector3f color({0.1f, 0.1f, 0.1f});

    for (int x = -100; x <= 100; x += 10) {
        PointPtr from = make_shared<Point3>(Point3({(float)x, -100.0f, 0.0f}));
        PointPtr to   = make_shared<Point3>(Point3({(float)x, 100.0f, 0.0f}));
        g_pGraphicsManager->DEBUG_SetDrawLineParam(*from, *to, color);
    }

    for (int y = -100; y <= 100; y += 10) {
        PointPtr from = make_shared<Point3>(Point3({-100.0f, (float)y, 0.0f}));
        PointPtr to   = make_shared<Point3>(Point3({100.0f, (float)y, 0.0f}));
        g_pGraphicsManager->DEBUG_SetDrawLineParam(*from, *to, color);
    }
}
#endif
