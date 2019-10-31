add_subdirectory(Empty)

if(OS_PSP2)
# Empty
endif(OS_PSP2)

if(OS_WINDOWS)
    # Windows specific code
    add_subdirectory(D2d)
    add_subdirectory(D3d)
endif(OS_WINDOWS)

if(OS_MACOS)
    # Darwin specific code
    add_subdirectory(Metal)
endif(OS_MACOS)

if(OS_WEBASSEMBLY)
    add_subdirectory(OpenGL)
endif(OS_WEBASSEMBLY)

