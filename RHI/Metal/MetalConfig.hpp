#pragma once
#include "Metal/MetalGraphicsManager.h"

namespace newbieGE {
GraphicsManager *g_pGraphicsManager = static_cast<GraphicsManager *>(new MetalGraphicsManager);
}  // namespace newbieGE
