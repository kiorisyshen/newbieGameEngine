# include_directories("/opt/local/include")
# link_directories("/opt/local/lib")
find_library(COCOA_LIBRARY Cocoa required)
# find_library(OPENGL_LIBRARY OpenGL required)
# find_library(CV_LIBRARY CoreVideo required)
# find_library(XG_LIBRARY xg PATHS ${MYGE_EXTERNAL_LIBRARY_PATH})

# NewbieGameEngineCocoa
add_executable(NewbieGameEngineCocoa MACOSX_BUNDLE
        CocoaApplication.mm 
        CocoaApplicationConfig.cpp 
        AppDelegate.m
        WindowDelegate.m
    )
target_link_libraries(NewbieGameEngineCocoa
        Common 
        # ${OPENGEX_LIBRARY} 
        # ${OPENDDL_LIBRARY} 
        # ${XG_LIBRARY} 
        ${COCOA_LIBRARY} 
        )
# __add_xg_platform_dependencies(NewbieGameEngineCocoa)

# # MyGameEngineCocoaOpenGL
# add_executable(NewbieGameEngineCocoaOpenGL MACOSX_BUNDLE
#         CocoaApplication.mm 
#         CocoaOpenGLApplication.mm
#         CocoaOpenGLApplicationConfig.cpp
#         AppDelegate.m
#         WindowDelegate.m
#         GLView.mm
#     )
# target_link_libraries(NewbieGameEngineCocoaOpenGL 
#         OpenGLRHI
#         Common
#         # ${OPENGEX_LIBRARY} 
#         # ${OPENDDL_LIBRARY} 
#         # ${XG_LIBRARY} 
#         ${COCOA_LIBRARY} 
#         ${OPENGL_LIBRARY}
#         # dl
#         )
# # __add_xg_platform_dependencies(MyGameEngineCocoaOpenGL)