add_library(OpenGLRHI OpenGLGraphicsManager.cpp
                      ${PROJECT_SOURCE_DIR}/External/glad/src/glad.c)
target_include_directories(
  OpenGLRHI
  PRIVATE "${PROJECT_SOURCE_DIR}/External/glad/include")
add_dependencies(OpenGLRHI GeomMath)
