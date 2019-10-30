#include "EditorLogic.hpp"
#include "GfxConfiguration.hpp"
#include "My/MyPhysicsManager.hpp"

#include "AnimationManager.hpp"
#include "AssetLoader.hpp"
#include "DebugManager.hpp"
#include "GraphicsManager.hpp"
#include "IPhysicsManager.hpp"
#include "InputManager.hpp"
#include "MemoryManager.hpp"

#include "CocoaMetalApplication.h"
#include "Metal/MetalConfig.hpp"

#if defined(OS_ANDROID) || defined(OS_WEBASSEMBLY)
#include "OpenGL/OpenGLESConfig.hpp"
#elif defined(OS_MACOS)
#include "Metal/MetalConfig.hpp"
#else
#include "Metal/MetalConfig.hpp"
// #include "OpenGL/OpenGLConfig.hpp"
#endif
// #include "RHI/Empty/EmptyConfig.hpp"

namespace newbieGE {
GfxConfiguration config(8, 8, 8, 8, 24, 8, 0, 960, 540, "NewbieGameEngine Editor");
IApplication *g_pApp                  = static_cast<IApplication *>(new CocoaMetalApplication(config));
IGameLogic *g_pGameLogic              = static_cast<IGameLogic *>(new EditorLogic);
IPhysicsManager *g_pPhysicsManager    = static_cast<IPhysicsManager *>(new MyPhysicsManager);
IMemoryManager *g_pMemoryManager      = static_cast<IMemoryManager *>(new MemoryManager);
AssetLoader *g_pAssetLoader           = static_cast<AssetLoader *>(new AssetLoader);
SceneManager *g_pSceneManager         = static_cast<SceneManager *>(new SceneManager);
InputManager *g_pInputManager         = static_cast<InputManager *>(new InputManager);
AnimationManager *g_pAnimationManager = static_cast<AnimationManager *>(new AnimationManager);
#ifdef DEBUG
DebugManager *g_pDebugManager = static_cast<DebugManager *>(new DebugManager);
#endif
}  // namespace newbieGE