#pragma once
#include "GraphicsManager.hpp"
#include "geommath.hpp"
#include <unordered_map>
#include <vector>
#include <string>
#include "portable.hpp"

OBJC_CLASS(MetalRenderer);

namespace newbieGE {
    class MetalGraphicsManager : public GraphicsManager
    {
    public:
        virtual int Initialize();
        virtual void Finalize();

        virtual void Tick();

        virtual void Clear();

        virtual void Draw();

        void SetRenderer(MetalRenderer* renderer) { m_pRenderer = renderer; }

    private:
        bool SetShaderParameters();

        void InitializeBuffers();
        void CalculateCameraPosition();
        void CalculateLights();
        bool InitializeShader(const char* vsFilename, const char* fsFilename);

    private:
        const float screenDepth = 1000.0f;
        const float screenNear = 0.1f;

        std::unordered_map<std::string, unsigned int> m_Buffers;

        PerFrameConstants   m_DrawFrameContext;
        MetalRenderer* m_pRenderer;
    };

}
