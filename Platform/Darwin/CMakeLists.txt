# include_directories("/opt/local/include")
# link_directories("/opt/local/lib")
find_library(COCOA_LIBRARY Cocoa required)
find_library(OPENGL_LIBRARY OpenGL required)
# find_library(CV_LIBRARY CoreVideo required)

# NewbieGameEngineCocoaOpenGL
add_executable(NewbieGameEngineCocoaOpenGL MACOSX_BUNDLE
        CocoaApplication.mm 
        CocoaOpenGLApplication.mm
        CocoaOpenGLApplicationConfig.cpp
        AppDelegate.m
        WindowDelegate.m
        GLView.mm
    )
target_link_libraries(NewbieGameEngineCocoaOpenGL 
        OpenGLRHI
        Common
        ${OPENGEX_LIBRARY} 
        ${OPENDDL_LIBRARY} 
        ${XG_LIBRARY} 
        ${COCOA_LIBRARY} 
        ${OPENGL_LIBRARY}
        # dl
        )
target_include_directories(NewbieGameEngineCocoaOpenGL PRIVATE "${PROJECT_SOURCE_DIR}/External/glad/include")
__add_xg_platform_dependencies(NewbieGameEngineCocoaOpenGL)