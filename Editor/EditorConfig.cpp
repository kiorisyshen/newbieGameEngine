#include "EditorLogic.hpp"
#include "GfxConfiguration.h"
#include "My/MyPhysicsManager.hpp"

namespace newbieGE
{
GfxConfiguration config(8, 8, 8, 8, 24, 8, 0, 960, 540, "NewbieGameEngine Editor");
IGameLogic*      g_pGameLogic      = static_cast<IGameLogic*>(new EditorLogic);
IPhysicsManager* g_pPhysicsManager = static_cast<IPhysicsManager*>(new MyPhysicsManager);
}  // namespace newbieGE