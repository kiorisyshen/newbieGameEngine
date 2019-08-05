#pragma once
#include <iostream>
#include "FrameStructure.hpp"
#include "Interface.hpp"

namespace newbieGE {
Interface IDrawPass {
   public:
    IDrawPass() = default;
    virtual ~IDrawPass(){};

    virtual RenderPassIndex GetPassIndex() = 0;
    virtual void Draw(Frame & frame)       = 0;
};
}  // namespace newbieGE