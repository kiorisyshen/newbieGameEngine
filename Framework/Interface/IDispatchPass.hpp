#pragma once
#include "Interface.hpp"

namespace newbieGE {
Interface IDispatchPass {
   public:
    IDispatchPass() = default;
    virtual ~IDispatchPass(){};

    virtual void Dispatch(void) = 0;
};
}  // namespace newbieGE
