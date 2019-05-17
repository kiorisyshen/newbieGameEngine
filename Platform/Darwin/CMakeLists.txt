find_library(COCOA_LIBRARY Cocoa required)
find_library(OPENGL_LIBRARY OpenGL required)
find_library(CV_LIBRARY CoreVideo required)

# NewbieGEMetalCocoa
add_executable(NewbieGEMetalCocoa MACOSX_BUNDLE
        CocoaApplication.mm 
        CocoaMetalApplication.mm
        CocoaMetalApplicationConfig.cpp
        AppDelegate.m
        WindowDelegate.m
        MetalView.mm
    )
target_link_libraries(NewbieGEMetalCocoa 
        MetalRHI
        Common
        ${OPENGEX_LIBRARY}
        ${OPENDDL_LIBRARY} 
        ${XG_LIBRARY} 
        ${COCOA_LIBRARY} 
        ${OPENGL_LIBRARY}
        # dl
        )
__add_xg_platform_dependencies(NewbieGEMetalCocoa)