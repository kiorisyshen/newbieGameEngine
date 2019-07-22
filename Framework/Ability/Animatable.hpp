#pragma once
#include "Ability.hpp"

namespace newbieGE
{
template <typename T>
Ability Animatable
{
    typedef const T ParamType;
    virtual void    Update(ParamType param) = 0;
};
}  // namespace newbieGE
