find_library(MTK_LIBRARY MetalKit required)
find_library(METAL_LIBRARY Metal required)

message(STATUS "MTK_LIBRARY: " ${MTK_LIBRARY})

add_library(MetalRHI MetalRenderer.mm MetalGraphicsManager.mm)

target_link_libraries(MetalRHI ${MTK_LIBRARY} ${METAL_LIBRARY})
target_include_directories(MetalRHI PUBLIC GeomMath)
target_link_libraries(MetalRHI GeomMath)

set_property(TARGET MetalRHI APPEND_STRING PROPERTY COMPILE_FLAGS "-fobjc-arc")
