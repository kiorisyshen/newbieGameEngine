#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"
#include "cbuffer.h"
#include "Scene.hpp"

namespace newbieGE
{
    struct DrawBatchConstants : public PerBatchConstants {
        uint32_t batchIndex;
        std::shared_ptr<SceneGeometryNode> node;
        
        virtual ~DrawBatchConstants() = default;
    };
    
    class GraphicsManager : implements IRuntimeModule
    {
      public:
            virtual ~GraphicsManager() = default;

            int Initialize() override;
            void Finalize() override;

            void Tick() override;

//        protected:
//            virtual void BeginScene() {};
//            virtual void EndScene() {}
//
//            virtual void BeginFrame() {}
//            virtual void EndFrame() {}
//
//            virtual void BeginPass() {}
//            virtual void EndPass() {}
//
//            virtual void BeginCompute() {}
//            virtual void EndCompute() {}

        private:
            void InitConstants();
        
            void CalculateCameraMatrix();
            void CalculateLights();
            void UpdateConstants();
        
            virtual void InitializeBuffers();
            virtual void RenderBuffers();
            virtual void SetPerFrameConstants(){};
            virtual void SetPerBatchConstants(){};

        protected:
            PerFrameConstants m_DrawFrameContext;
            std::vector<std::shared_ptr<DrawBatchConstants> > m_DrawBatchContext;

            uint32_t m_nFrameIndex = 0;

            // std::vector<Frame>  m_Frames;
            // std::vector<std::shared_ptr<IDispatchPass>> m_InitPasses;
            // std::vector<std::shared_ptr<IDrawPass>> m_DrawPasses;
    };

    extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
