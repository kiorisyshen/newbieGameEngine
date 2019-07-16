IF(ANDROID)
    add_library(DebugInfo SHARED 
        DebugInfo_logic.cpp DebugInfo_config.cpp)
ELSEIF(APPLE)
    set(SHADER_SOURCES basic debugInfo)
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
            COMMENT "Compile Main.metalar --> Main.metallib"
            DEPENDS Main.metalar
        )

    add_executable(DebugInfo MACOSX_BUNDLE
                   DebugInfo_logic.cpp 
                   DebugInfo_config.cpp
                   Main.metallib)
    set(RESOURCE_FILES
        Main.metallib
    )
    set_target_properties(DebugInfo PROPERTIES
        RESOURCE "${RESOURCE_FILES}"
    )
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

