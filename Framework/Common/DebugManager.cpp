#include "DebugManager.hpp"
#include <iostream>
#include "GraphicsManager.hpp"
#include "IGameLogic.hpp"
#include "IPhysicsManager.hpp"

using namespace newbieGE;
using namespace std;

#ifdef DEBUG
int DebugManager::Initialize() {
    return 0;
}

void DebugManager::Finalize() {
}

void DebugManager::Tick() {
    if (g_pGraphicsManager->DEBUG_IsShowDebug()) {
        g_pGraphicsManager->DEBUG_ClearDebugBuffers();
        DrawDebugInfo();
        g_pPhysicsManager->DrawDebugInfo();
        g_pGameLogic->DrawDebugInfo();
        g_pGraphicsManager->DEBUG_SetBuffer();
    }
}

void DebugManager::ToggleDebugInfo() {
    g_pGraphicsManager->DEBUG_ToggleDebugInfo();
}

void DebugManager::DrawDebugInfo() {
    DrawGrid();
    DrawAxis();
}

void DebugManager::DrawAxis() {
    // x - axis
    Vector3f from({0.0f, 0.0f, 0.0f});
    Vector3f to({1000.0f, 0.0f, 0.0f});
    Vector3f color({1.0f, 0.0f, 0.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);

    // y - axis
    from.Set({0.0f, 0.0f, 0.0f});
    to.Set({0.0f, 1000.0f, 0.0f});
    color.Set({0.0f, 1.0f, 0.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);

    // z - axis
    from.Set({0.0f, 0.0f, 0.0f});
    to.Set({0.0f, 0.0f, 1000.0f});
    color.Set({0.0f, 0.0f, 1.0f});
    g_pGraphicsManager->DEBUG_SetDrawLineParam(from, to, color);
}

void DebugManager::DrawGrid() {
    Vector3f color({0.1f, 0.1f, 0.1f});

    for (int x = -100; x <= 100; x += 10) {
        PointPtr from, to;
        if (x == 0) {
            from = make_shared<Point3>(Point3({(float)x, -100.0f, 0.0f}));
            to   = make_shared<Point3>(Point3({(float)x, 0.0f, 0.0f}));
        } else {
            from = make_shared<Point3>(Point3({(float)x, -100.0f, 0.0f}));
            to   = make_shared<Point3>(Point3({(float)x, 100.0f, 0.0f}));
        }

        g_pGraphicsManager->DEBUG_SetDrawLineParam(*from, *to, color);
    }

    for (int y = -100; y <= 100; y += 10) {
        PointPtr from, to;
        if (y == 0) {
            from = make_shared<Point3>(Point3({-100.0f, (float)y, 0.0f}));
            to   = make_shared<Point3>(Point3({0.0f, (float)y, 0.0f}));
        } else {
            from = make_shared<Point3>(Point3({-100.0f, (float)y, 0.0f}));
            to   = make_shared<Point3>(Point3({100.0f, (float)y, 0.0f}));
        }

        g_pGraphicsManager->DEBUG_SetDrawLineParam(*from, *to, color);
    }
}
#endif
