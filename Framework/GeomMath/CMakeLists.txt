set(GEOMMATH_LIB_FILE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}GeomMath${CMAKE_STATIC_LIBRARY_SUFFIX})
if(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows")
    set(ISPC_COMPILER_PATH ${PROJECT_SOURCE_DIR}/External/Windows/bin/)
    set(ISPC_COMPILER ispc.exe)
    if(NOT ${CMAKE_CROSSCOMPILING})
        if(${ARCH_BIT} MATCHES 64)
            set(ISPC_OPTIONS --arch=x86-64 --target=host)
            set(CMAKE_AR lib)
            set(ISPC_LIBRARIAN_OPTIONS /MACHINE:X64 /OUT:${GEOMMATH_LIB_FILE})
        else()
            set(ISPC_OPTIONS --arch=x86 --target=host)
            set(CMAKE_AR lib)
            set(ISPC_LIBRARIAN_OPTIONS /MACHINE:X86 /OUT:${GEOMMATH_LIB_FILE})
        endif()
    else()
        if(${CMAKE_SYSTEM_NAME} MATCHES Orbis)
            set(ISPC_COMPILER orbis-ispc.exe)
            set(CMAKE_AR ${SNC_TOOLCHAIN_DIR}orbis-snarl -rcv ${GEOMMATH_LIB_FILE})
        elseif(${CMAKE_SYSTEM_NAME} MATCHES PSP2)
            set(ISPC_OPTIONS --arch=arm --cpu=cortex-a9 --target=neon-i32x4)
            set(CMAKE_AR ${SNC_TOOLCHAIN_DIR}psp2snarl -rcv ${GEOMMATH_LIB_FILE})
        endif()
    endif()
elseif(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Darwin")
    set(ISPC_COMPILER_PATH ${PROJECT_SOURCE_DIR}/External/Darwin/bin/)
    set(ISPC_COMPILER ispc)
    set(ISPC_OPTIONS --arch=x86-64 --target=host)
    set(ISPC_LIBRARIAN_OPTIONS -rcv ${GEOMMATH_LIB_FILE})
elseif(${CMAKE_HOST_SYSTEM_NAME} MATCHES "FreeBSD")
    set(ISPC_COMPILER_PATH ${PROJECT_SOURCE_DIR}/External/FreeBSD/bin/)
    set(ISPC_COMPILER ispc)
    set(ISPC_OPTIONS --arch=x86-64 --target=host)
    set(ISPC_LIBRARIAN_OPTIONS -rcv ${GEOMMATH_LIB_FILE})
else(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows")
    set(ISPC_COMPILER_PATH ${PROJECT_SOURCE_DIR}/External/`uname -s`/bin/)
    set(ISPC_COMPILER ispc)
    set(ISPC_OPTIONS --arch=x86-64 --target=host)
    set(ISPC_LIBRARIAN_OPTIONS -rcv -o ${GEOMMATH_LIB_FILE})
endif(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows")

# set(GEOMMATH_LIB_HEADER_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(ISPC_OPTIONS ${ISPC_OPTIONS} -O2)
set(GEOMMATH_LIB_HEADER_FOLDER ${CMAKE_CURRENT_BINARY_DIR})

add_library(GeomMath
            STATIC
            IMPORTED
            GLOBAL)
add_dependencies(GeomMath GeomMathLib)

set_target_properties(GeomMath
                      PROPERTIES IMPORTED_LOCATION
                                 ${GEOMMATH_LIB_FILE}
                                 INTERFACE_INCLUDE_DIRECTORIES
                                 ${GEOMMATH_LIB_HEADER_FOLDER})

add_subdirectory(ispc)
