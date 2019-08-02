#pragma once
#include "IRuntimeModule.hpp"

namespace newbieGE {
Interface IMemoryManager : implements IRuntimeModule {
   public:
    virtual int Initialize() = 0;
    virtual void Finalize()  = 0;
    virtual void Tick()      = 0;

    virtual void *AllocatePage(size_t size) = 0;
    virtual void FreePage(void *p)          = 0;
};

extern IMemoryManager *g_pMemoryManager;
}  // namespace newbieGE