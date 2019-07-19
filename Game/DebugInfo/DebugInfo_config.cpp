#include "GfxConfiguration.h"
#include "DebugInfo_logic.hpp"
#include "My/MyPhysicsManager.hpp"

namespace newbieGE
{
GfxConfiguration config(8, 8, 8, 8, 24, 8, 0, 960, 540, "Debug Info");
IGameLogic *g_pGameLogic = static_cast<IGameLogic *>(new DebugInfo_logic);
IPhysicsManager *g_pPhysicsManager = static_cast<IPhysicsManager *>(new MyPhysicsManager);
} // namespace newbieGE