find_library(MTK_LIBRARY MetalKit required)
find_library(METAL_LIBRARY Metal required)

message(STATUS "MTK_LIBRARY: " ${MTK_LIBRARY})

add_library(MetalRHI MetalRenderer.mm MetalGraphicsManager.mm)

target_link_libraries(MetalRHI ${MTK_LIBRARY} ${METAL_LIBRARY})
