#pragma once
#include "OpenGL/OpenGLESGraphicsManager.hpp"

namespace newbieGE {
GraphicsManager *g_pGraphicsManager = static_cast<GraphicsManager *>(new OpenGLESGraphicsManager);
}  // namespace newbieGE
