#include "CocoaMetalApplication.h"
#include "Metal/MetalGraphicsManager.h"

namespace newbieGE {
    extern GfxConfiguration config;
    IApplication* g_pApp                = static_cast<IApplication*>(new CocoaMetalApplication(config));
    GraphicsManager* g_pGraphicsManager = static_cast<GraphicsManager*>(new MetalGraphicsManager);
    MemoryManager*   g_pMemoryManager   = static_cast<MemoryManager*>(new MemoryManager);
    AssetLoader*     g_pAssetLoader     = static_cast<AssetLoader*>(new AssetLoader);
    SceneManager*    g_pSceneManager    = static_cast<SceneManager*>(new SceneManager);
    InputManager*    g_pInputManager    = static_cast<InputManager*>(new InputManager);
    PhysicsManager*  g_pPhysicsManager  = static_cast<PhysicsManager*>(new PhysicsManager);
}
