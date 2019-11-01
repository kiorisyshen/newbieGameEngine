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
    # target_link_libraries(Editor MyPhysics newbieGameEngine)
    # add_custom_command(TARGET Editor POST_BUILD
    #                    COMMAND ${CMAKE_COMMAND}
    #                            -E
    #                            copy_if_different
    #                            "${PROJECT_SOURCE_DIR}/External/Windows/bin/zlib.dll"
    #                            $<TARGET_FILE_DIR:Editor>)
elseif(WA)
    target_link_libraries(Editor
                            MyPhysics
                            Common
                            Sdl
                            OpenGLRHI)

    add_custom_target(basicAssets ALL
        python $ENV{EMSCRIPTEN}/tools/file_packager.py ${CMAKE_CURRENT_BINARY_DIR}/Asset.data 
            --lz4
            --no-heap-copy
            --js-output=${CMAKE_CURRENT_BINARY_DIR}/Asset.preload.js 
            --preload Asset/Scene/test.ogex
                    Asset/Shaders/WebGL
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        VERBATIM
            )

    set_target_properties(Editor
            PROPERTIES LINK_FLAGS "-s FULL_ES2=1 -s FULL_ES3=1 -s USE_WEBGL2=1 -s USE_SDL=2 -s DEMANGLE_SUPPORT=1 --shell-file ${CMAKE_CURRENT_SOURCE_DIR}/Editor.html"
            )
else(WIN32)
    target_link_libraries(Editor
                            MyPhysics
                            Common
                            PlatformInterface
                            MetalRHI)
endif(WIN32)
