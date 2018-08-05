#pragma once
#include "GraphicsManager.hpp"

namespace newbieGE {
    class OpenGLGraphicsManager : public GraphicsManager
    {
    public:
        virtual int Initialize();
        virtual void Finalize();

        virtual void Tick();
    private:
    };
}