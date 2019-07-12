IF(ANDROID)
add_library(DebugInfo SHARED 
    DebugInfo_logic.cpp DebugInfo_config.cpp)
ELSEIF(APPLE)
add_executable(DebugInfo MACOSX_BUNDLE
    DebugInfo_logic.cpp DebugInfo_config.cpp)
ELSE(ANDROID)
add_executable(DebugInfo
    DebugInfo_logic.cpp DebugInfo_config.cpp)
ENDIF(ANDROID)
target_link_libraries(DebugInfo
                        MyPhysics
                        newbieGameEngine
                     )
IF(WIN32)
add_custom_command(TARGET DebugInfo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${PROJECT_SOURCE_DIR}/External/Windows/bin/zlib.dll"
        $<TARGET_FILE_DIR:DebugInfo>)
ENDIF(WIN32)

