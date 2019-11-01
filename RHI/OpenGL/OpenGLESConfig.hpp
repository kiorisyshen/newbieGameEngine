#pragma once
#include "OpenGL/OpenGLGraphicsManagerCommonBase.hpp"

namespace newbieGE {
GraphicsManager *g_pGraphicsManager = static_cast<GraphicsManager *>(new OpenGLGraphicsManagerCommonBase);
}  // namespace newbieGE
