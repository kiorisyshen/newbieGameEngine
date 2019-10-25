#include "EditorLogic.hpp"
#include "AnimationManager.hpp"
#include "IApplication.hpp"
#include "SceneManager.hpp"

using namespace newbieGE;
using namespace std;

int EditorLogic::Initialize() {
    int result;

    cout << "[EditorLogic] Editor Logic Initialize" << endl;

    if (g_pApp->GetCommandLineArgumentsCount() > 1) {
        auto scene_filename = g_pApp->GetCommandLineArgument(1);
        cout << "[EditorLogic] Loading Scene: " << scene_filename << endl;
        result = g_pSceneManager->LoadScene(scene_filename);
    } else {
        cout << "[EditorLogic] Loading Splash Scene" << endl;
        result = g_pSceneManager->LoadScene("Scene/ground.ogex");
    }

    return result;
}

void EditorLogic::Finalize() {
    cout << "[EditorLogic] Finalize" << endl;
}

void EditorLogic::Tick() {
}

#ifdef DEBUG
void EditorLogic::DrawDebugInfo() {
}
#endif

void EditorLogic::OnLeftKeyDown() {
    auto &scene      = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode) {
        pCameraNode->RotateBy(0.0f, 0.0f, PI / 90.0);
    }
}

void EditorLogic::OnRightKeyDown() {
    auto &scene      = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode) {
        pCameraNode->RotateBy(0.0f, 0.0f, -PI / 90.0);
    }
}

void EditorLogic::OnUpKeyDown() {
    auto &scene      = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode) {
        pCameraNode->MoveBy({0.0, 0.0, 1.0});
    }
}

void EditorLogic::OnDownKeyDown() {
    auto &scene      = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();
    if (pCameraNode) {
        pCameraNode->MoveBy({0.0, 0.0, -1.0});
    }
}

void EditorLogic::OnButton1Down(char keycode) {
#ifdef DEBUG
    cerr << "[EditorLogic] ASCII Key Down! (" << keycode << ")" << endl;
#endif
    auto &scene      = g_pSceneManager->GetSceneForRendering();
    auto pCameraNode = scene.GetFirstCameraNode();

    switch (keycode) {
        case 'w':
            if (pCameraNode) {
                Matrix3X3f local_axis = pCameraNode->GetLocalAxis();
                Vector2f direction    = {-local_axis[2].data[0], -local_axis[2].data[1]};
                Normalize(direction);
                pCameraNode->MoveBy(direction.data[0], direction.data[1], 0.0);
            }
            break;
        case 's':
            if (pCameraNode) {
                Matrix3X3f local_axis = pCameraNode->GetLocalAxis();
                Vector2f direction    = {local_axis[2].data[0], local_axis[2].data[1]};
                Normalize(direction);
                pCameraNode->MoveBy(direction.data[0], direction.data[1], 0.0);
            }
            break;
        default:
            cerr << "[EditorLogic] unhandled key." << endl;
    }
}

void EditorLogic::OnButton1Up(char keycode) {
#ifdef DEBUG
    cerr << "[EditorLogic] ASCII Key up! (" << keycode << ")" << endl;
#endif
    switch (keycode) {
        case 'w':
            break;
        case 's':
            break;
        default:
            cerr << "[EditorLogic] unhandled key." << endl;
    }
}

void EditorLogic::OnAnalogStick(int id, float deltaX, float deltaY) {
    if (id == 0) {
        auto &scene      = g_pSceneManager->GetSceneForRendering();
        auto pCameraNode = scene.GetFirstCameraNode();
        if (pCameraNode) {
            auto screen_width  = g_pApp->GetConfiguration().screenWidth;
            auto screen_height = g_pApp->GetConfiguration().screenHeight;

            pCameraNode->RotateBy(0.0, 0.0, deltaX / screen_width * PI);

            Vector3f axis = pCameraNode->GetLocalAxis()[0];
            Normalize(axis);

            pCameraNode->RotateBy(axis, deltaY / screen_height * PI);
        }
    }
}
