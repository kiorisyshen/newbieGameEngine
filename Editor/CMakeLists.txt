if(APPLE)
    set(SHADER_SOURCES
        # basic
        debugInfo
        shadowmap
        texture2dOverlay
        skybox
        terrain
        integrateBRDF.comp
        pbr)
    foreach(SHADER
            IN
            LISTS
            SHADER_SOURCES)
        add_custom_command(OUTPUT ${SHADER}.air
                           COMMAND xcrun
                                   -sdk
                                   macosx
                                   metal
                                   -g
                                   -MO
                                   -c
                                   ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal
                                   -o
                                   ${SHADER}.air
                           COMMENT "Compile ${SHADER}.metal --> ${SHADER}.air"
                           DEPENDS ${PROJECT_SOURCE_DIR}/Asset/Shaders/${SHADER}.metal)
        list(APPEND AIRS ${SHADER}.air)
    endforeach(SHADER)

    add_custom_command(OUTPUT Main.metalar
                       COMMAND xcrun
                               -sdk
                               macosx
                               metal-ar
                               rcv
                               Main.metalar
                               ${AIRS}
                       COMMENT "Archive ${AIRS} --> Main.metalar"
                       DEPENDS ${AIRS})

    add_custom_command(OUTPUT Main.metallib
                       COMMAND xcrun
                               -sdk
                               macosx
                               metallib
                               Main.metalar
                               -split-module-without-linking
                               -o
                               Main.metallib
                       COMMENT "Compile Main.metalar --> Main.metallib"
                       DEPENDS Main.metalar)
    add_executable(Editor MACOSX_BUNDLE EditorLogic.cpp EditorConfig.cpp Main.metallib)
    set(RESOURCE_FILES Main.metallib)
    set_target_properties(Editor PROPERTIES RESOURCE "${RESOURCE_FILES}")
else(APPLE)
    add_executable(Editor EditorLogic.cpp EditorConfig.cpp)
endif(APPLE)
if(WIN32)
    target_link_libraries(Editor MyPhysics newbieGameEngine)
    add_custom_command(TARGET Editor POST_BUILD
                       COMMAND ${CMAKE_COMMAND}
                               -E
                               copy_if_different
                               "${PROJECT_SOURCE_DIR}/External/Windows/bin/zlib.dll"
                               $<TARGET_FILE_DIR:Editor>)
else(WIN32)
    target_link_libraries(Editor MyPhysics newbieGameEngine)
endif(WIN32)
