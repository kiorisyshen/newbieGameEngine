#pragma once
#include "IDispatchPass.hpp"

namespace newbieGE {
class BRDFIntegrator : implements IDispatchPass {
   public:
    ~BRDFIntegrator() = default;
    void Dispatch(void) final;
};
}  // namespace newbieGE