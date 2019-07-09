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

        virtual void Draw();

        void SetRenderer(MetalRenderer* renderer) { m_pRenderer = renderer; }
    
    protected:
        bool SetPerFrameShaderParameters();
        void InitializeBuffers();
        void RenderBuffers();

    private:
        const float screenDepth = 1000.0f;
        const float screenNear = 0.1f;

        MetalRenderer* m_pRenderer;
    };

}
