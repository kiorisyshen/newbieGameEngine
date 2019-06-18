find_library(COCOA_LIBRARY Cocoa required)
find_library(OPENGL_LIBRARY OpenGL required)
find_library(CV_LIBRARY CoreVideo required)

# Platform Interface library
add_library(PlatformInterface
        CocoaApplication.mm 
        CocoaMetalApplication.mm
        AppDelegate.m
        WindowDelegate.m
        MetalView.mm
    )

target_link_libraries(PlatformInterface
    ${COCOA_LIBRARY} 
    ${OPENGL_LIBRARY}
    # dl
)

# newbieGameEngine Metal
add_library(newbieGameEngine
        CocoaMetalApplicationConfig.cpp
    )
target_link_libraries(newbieGameEngine
        Common 
        PlatformInterface
        MetalRHI
        )

# # NewbieGEMetalCocoa
# add_executable(NewbieGEMetalCocoa MACOSX_BUNDLE
#         CocoaApplication.mm 
#         CocoaMetalApplication.mm
#         CocoaMetalApplicationConfig.cpp
#         AppDelegate.m
#         WindowDelegate.m
#         MetalView.mm
#         Main.metallib
#     )
# set(RESOURCE_FILES
#     Main.metallib
# )
# set_target_properties(NewbieGEMetalCocoa PROPERTIES
#     RESOURCE "${RESOURCE_FILES}"
# )
# target_link_libraries(NewbieGEMetalCocoa 
#         MetalRHI
#         Common
#         ${COCOA_LIBRARY} 
#         ${OPENGL_LIBRARY}
#         # dl
#         )
# __add_xg_platform_dependencies(NewbieGEMetalCocoa)