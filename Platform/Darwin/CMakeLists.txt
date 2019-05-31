find_library(COCOA_LIBRARY Cocoa required)
find_library(OPENGL_LIBRARY OpenGL required)
find_library(CV_LIBRARY CoreVideo required)

set(SHADER_SOURCES basic)
foreach(SHADER IN LISTS SHADER_SOURCES)
    add_custom_command(OUTPUT ${SHADER}.air
        COMMAND xcrun -sdk macosx metal -g -MO -c ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal -o ${SHADER}.air
        COMMENT "Compile ${SHADER}.metal --> ${SHADER}.air"
        DEPENDS ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal
        )
    list(APPEND AIRS ${SHADER}.air)
endforeach(SHADER)

add_custom_command(OUTPUT Main.metalar
        COMMAND xcrun -sdk macosx metal-ar rcv Main.metalar ${AIRS}
        COMMENT "Archive ${AIRS} --> Main.metalar"
        DEPENDS ${AIRS}
    )

add_custom_command(OUTPUT Main.metallib
        COMMAND xcrun -sdk macosx metallib Main.metalar -split-module-without-linking -o Main.metallib
        COMMENT "Compile Editor.metalar --> Main.metallib"
        DEPENDS Main.metalar
    )

# NewbieGEMetalCocoa
add_executable(NewbieGEMetalCocoa MACOSX_BUNDLE
        CocoaApplication.mm 
        CocoaMetalApplication.mm
        CocoaMetalApplicationConfig.cpp
        AppDelegate.m
        WindowDelegate.m
        MetalView.mm
        Main.metallib
    )
set(RESOURCE_FILES
    Main.metallib
)
set_target_properties(NewbieGEMetalCocoa PROPERTIES
    RESOURCE "${RESOURCE_FILES}"
)
target_link_libraries(NewbieGEMetalCocoa 
        MetalRHI
        Common
        ${OPENGEX_LIBRARY}
        ${OPENDDL_LIBRARY} 
        ${XG_LIBRARY} 
        ${COCOA_LIBRARY} 
        ${OPENGL_LIBRARY}
        ${ZLIB_LIBRARY}
        # dl
        )
__add_xg_platform_dependencies(NewbieGEMetalCocoa)