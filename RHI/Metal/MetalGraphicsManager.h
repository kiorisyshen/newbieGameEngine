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
        int Initialize() final;
        void Finalize() final;

        void SetRenderer(MetalRenderer* renderer) { m_pRenderer = renderer; }
        
        void RenderBuffers() final;

    private:
        void InitializeBuffers() final;
        void SetPerFrameConstants() final;
        void SetPerBatchConstants() final;

        MetalRenderer* m_pRenderer;
    };

}
