#pragma once

namespace newbieGE {
class OpenGLShaderManagerCommonBase {
   public:
    OpenGLShaderManagerCommonBase()  = default;
    ~OpenGLShaderManagerCommonBase() = default;

    bool InitializeShaders();
    void ClearShaders();
};
}  // namespace newbieGE