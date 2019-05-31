#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"

namespace newbieGE
{
    struct PerFrameConstants
    {
        Matrix4X4f  m_worldMatrix;
        Matrix4X4f  m_viewMatrix;
        Matrix4X4f  m_projectionMatrix;
        Vector3f    m_lightPosition;
        Vector4f    m_lightColor;
    };

    struct PerBatchConstants
    {
        Matrix4X4f m_objectLocalMatrix;
        Vector3f   m_diffuseColor;
        Vector3f   m_specularColor;
        float      m_specularPower;
    };
    
    class GraphicsManager : implements IRuntimeModule
    {
      public:
            virtual ~GraphicsManager() {}

            virtual int Initialize();
            virtual void Finalize();

            virtual void Tick();

            virtual void Clear();
            virtual void Draw();

            // temporary. should be moved to scene manager and script engine (policy engine)
            void WorldRotateX(float radians);
            void WorldRotateY(float radians);

        protected:
            bool SetPerFrameShaderParameters();

            void InitConstants();
            void InitializeBuffers();
            void CalculateCameraMatrix();
            void CalculateLights();
            void RenderBuffers();

            PerFrameConstants m_DrawFrameContext;
    };

    extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
