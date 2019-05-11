#pragma once
#include <memory>
#include <string>
#include "Interface.hpp"
#include "SceneNode.hpp"

namespace newbieGE {
    Interface SceneParser
    {
    public:
        virtual std::unique_ptr<BaseSceneNode> Parse(const std::string& buf) = 0;
    };
}

