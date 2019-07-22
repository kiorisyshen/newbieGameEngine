#pragma once
#include "Buffer.hpp"
#include "Image.hpp"
#include "Interface.hpp"

namespace newbieGE
{
Interface ImageParser
{
   public:
    virtual Image Parse(Buffer & buf) = 0;
};
}  // namespace newbieGE
