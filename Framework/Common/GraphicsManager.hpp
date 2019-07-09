#pragma once
#include "IRuntimeModule.hpp"
#include "geommath.hpp"
#include "cbuffer.h"

namespace newbieGE
{
    class GraphicsManager : implements IRuntimeModule
    {
      public:
            virtual ~GraphicsManager() = default;

            int Initialize() override;
            void Finalize() override;

            void Tick() override;

            virtual void Draw();

            virtual void DrawBatch(const std::vector<std::shared_ptr<PerBatchConstants>>& batches) {}

        protected:
            virtual void BeginScene() {};
            virtual void EndScene() {}

            virtual void BeginFrame() {}
            virtual void EndFrame() {}

            virtual void BeginPass() {}
            virtual void EndPass() {}

            virtual void BeginCompute() {}
            virtual void EndCompute() {}

            bool SetPerFrameShaderParameters();

        private:
            void InitConstants();
            void InitializeBuffers();
            void CalculateCameraMatrix();
            void CalculateLights();
            void RenderBuffers();

        protected:
            PerFrameConstants m_DrawFrameContext;

            uint32_t m_nFrameIndex = 0;

            // std::vector<Frame>  m_Frames;
            // std::vector<std::shared_ptr<IDispatchPass>> m_InitPasses;
            // std::vector<std::shared_ptr<IDrawPass>> m_DrawPasses;
    };

    extern GraphicsManager *g_pGraphicsManager;
} // namespace newbieGE
