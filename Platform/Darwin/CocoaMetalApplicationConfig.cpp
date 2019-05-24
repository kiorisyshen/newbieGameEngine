#include "CocoaMetalApplication.h"
#include "MemoryManager.hpp"
#include "AssetLoader.hpp"
#include "SceneManager.hpp"
#include "Metal/MetalGraphicsManager.h"

namespace newbieGE {
    GfxConfiguration config(8, 8, 8, 8, 24, 8, 0, 960, 540, "NewbieGE (MacOS Cocoa Metal)");
    IApplication* g_pApp                = static_cast<IApplication*>(new CocoaMetalApplication(config));
    GraphicsManager* g_pGraphicsManager = static_cast<GraphicsManager*>(new MetalGraphicsManager);
    MemoryManager*   g_pMemoryManager   = static_cast<MemoryManager*>(new MemoryManager);
    AssetLoader*     g_pAssetLoader     = static_cast<AssetLoader*>(new AssetLoader);
    SceneManager*    g_pSceneManager    = static_cast<SceneManager*>(new SceneManager);
}