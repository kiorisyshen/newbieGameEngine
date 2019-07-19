#include "GfxConfiguration.h"
#include "EditorLogic.hpp"
#include "Bullet/BulletPhysicsManager.hpp"

namespace newbieGE
{
GfxConfiguration config(8, 8, 8, 8, 24, 8, 0, 960, 540, "GameEngineFromScratch Editor");
IGameLogic *g_pGameLogic = static_cast<IGameLogic *>(new EditorLogic);
IPhysicsManager *g_pPhysicsManager = static_cast<IPhysicsManager *>(new BulletPhysicsManager);
} // namespace newbieGE