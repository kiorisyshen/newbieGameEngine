find_library(MTK_LIBRARY MetalKit required)
find_library(METAL_LIBRARY Metal required)

MESSAGE( STATUS "MTK_LIBRARY: " ${MTK_LIBRARY} )

# set(SHADER_SOURCES basic)
# foreach(SHADER IN LISTS SHADER_SOURCES)
#     add_custom_command(OUTPUT ${SHADER}.air
#         COMMAND xcrun -sdk macosx metal -g -MO -c ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal -o ${SHADER}.air
#         COMMENT "Compile ${SHADER}.metal --> ${SHADER}.air"
#         DEPENDS ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal
#         )
#     list(APPEND AIRS ${SHADER}.air)
# endforeach(SHADER)

# add_custom_command(OUTPUT Main.metalar
#         COMMAND xcrun -sdk macosx metal-ar rcv Main.metalar ${AIRS}
#         COMMENT "Archive ${AIRS} --> Main.metalar"
#         DEPENDS ${AIRS}
#     )

# add_custom_command(OUTPUT Main.metallib
#         COMMAND xcrun -sdk macosx metallib Main.metalar -split-module-without-linking -o Main.metallib
#         COMMENT "Compile Editor.metalar --> Main.metallib"
#         DEPENDS Main.metalar
#     )

add_library(MetalRHI
    MetalRenderer.mm
    MetalGraphicsManager.mm
    ${PROJECT_SOURCE_DIR}/Asset/Shaders/basic.metal
    # Main.metallib
    )

target_link_libraries(MetalRHI
        ${MTK_LIBRARY} 
        ${METAL_LIBRARY}
    )
