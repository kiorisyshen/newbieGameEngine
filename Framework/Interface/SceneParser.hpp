#pragma once
#include "Interface.hpp"
#include "Scene.hpp"

namespace newbieGE {
Interface SceneParser {
   public:
    virtual std::unique_ptr<Scene> Parse(const std::string &buf) = 0;
};
}  // namespace newbieGE
