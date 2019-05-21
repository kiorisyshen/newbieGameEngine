#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"

namespace newbieGE
{
class GraphicsManager : implements IRuntimeModule
{
  public:
    virtual ~GraphicsManager() {}

    virtual int Initialize();
    virtual void Finalize();

    virtual void Tick();

    virtual void Clear();
    virtual void Draw();
};
    
struct PerFrameConstants
{
    Matrix4X4f  m_worldMatrix;
    Matrix4X4f  m_viewMatrix;
    Matrix4X4f  m_projectionMatrix;
    Vector3f    m_lightPosition;
    Vector4f    m_lightColor;
};

extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
