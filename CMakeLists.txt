cmake_minimum_required(VERSION 3.1)
project(newbieGameEngine)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set (USE_ISPC 1)
IF(${UNIX})
    IF(${APPLE})
        set(NBGE_TARGET_PLATFORM "Darwin")
        set(OS_MACOS 1)
    ELSEIF(${CMAKE_SYSTEM_NAME} MATCHES Android)
        set(NBGE_TARGET_PLATFORM "Android")
        set(ANDROID 1)
        set(OS_ANDROID 1)
    ELSEIF(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
        set(NBGE_TARGET_PLATFORM "FreeBSD")
        include_directories("/usr/local/include")
        set(BSD 1)
        set(OS_BSD 1)
    ELSEIF(${CMAKE_SYSTEM_NAME} MATCHES Emscripten)
        set(NBGE_TARGET_PLATFORM "Emscripten")
        set(WA 1)
        set(OS_WEBASSEMBLY 1)
        unset (USE_ISPC)
    ELSE(${APPLE})
        set(NBGE_TARGET_PLATFORM "Linux")
        set(OS_LINUX 1)
    ENDIF(${APPLE})
ELSEIF(${WIN32})
    set(NBGE_TARGET_PLATFORM "Windows")
    set(OS_WINDOWS 1)
ELSEIF(${CMAKE_SYSTEM_NAME} MATCHES Psp2)
    set(NBGE_TARGET_PLATFORM "PSP2")
    set(PSP2 1)
    set(OS_PSP2 1)
ENDIF(${UNIX})

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-function -Wunused-variable")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-function -Wunused-variable")

if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /D _CRT_SECURE_NO_WARNINGS")
endif(MSVC)

if(ANDROID)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-command-line-argument")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-command-line-argument")
endif(ANDROID)

if(WA)
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s FORCE_FILESYSTEM=1 -s LZ4=1 --emrun")
    set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g4 --source-map-base http://localhost:8080/")
endif(WA)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${CMAKE_C_FLAGS} -DDEBUG -D_DEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${CMAKE_CXX_FLAGS} -DDEBUG -D_DEBUG")

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS}")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(TargetArchDetect)
target_architecture(TARGET_ARCH)

if((TARGET_ARCH MATCHES "x86_64" OR TARGET_ARCH MATCHES "ia64") AND NOT OF_32BIT)
    set(ARCH_BIT 64)
else()
    set(ARCH_BIT 32)
endif()

set(NBGE_EXTERNAL_ROOT ${PROJECT_SOURCE_DIR}/External/${NBGE_TARGET_PLATFORM})
set(NBGE_EXTERNAL_INCLUDE_PATH ${NBGE_EXTERNAL_ROOT}/include)
set(NBGE_EXTERNAL_LIBRARY_PATH ${NBGE_EXTERNAL_ROOT}/lib)

include_directories("${NBGE_EXTERNAL_INCLUDE_PATH}")
include_directories("${NBGE_EXTERNAL_INCLUDE_PATH}/bullet")
include_directories("${PROJECT_SOURCE_DIR}")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Ability")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Algorithm")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Common")
include_directories("${PROJECT_SOURCE_DIR}/Framework/DrawPass")
include_directories("${PROJECT_SOURCE_DIR}/Framework/DispatchPass")
include_directories("${PROJECT_SOURCE_DIR}/Framework/GeomMath")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Geometries")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Interface")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Parser/")
include_directories("${PROJECT_SOURCE_DIR}/Physics")
include_directories("${PROJECT_SOURCE_DIR}/RHI")
include_directories("${PROJECT_SOURCE_DIR}/Platform/Empty")
include_directories("${PROJECT_SOURCE_DIR}/Platform/${NBGE_TARGET_PLATFORM}")

find_library(XG_LIBRARY xg PATHS ${NBGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
find_library(OPENDDL_LIBRARY OpenDDL PATHS ${NBGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
find_library(OPENGEX_LIBRARY OpenGEX PATHS ${NBGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
find_library(ZLIB_LIBRARY NAMES z zlib PATHS ${NBGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
include(CTest)
include(CheckCXXSourceCompiles)
include(PlatformDependencies)
check_cxx_source_compiles("#include <memory>
int main(int argc, char** argv)
{
    std::unique_ptr<int> my_int = std::make_unique<int>();
    *my_int = 0;
    return *my_int;
}
" HAVE_MAKE_UNIQUE)
check_cxx_source_compiles("#include <algorithm>

int main(int argc, char** argv)
{
    int result = -1;
    result = std::clamp(result, 0, 1);
    return result;
}
" HAVE_CLAMP)

configure_file(${PROJECT_SOURCE_DIR}/config.h.in ${PROJECT_SOURCE_DIR}/config.h)
add_subdirectory(Framework)
add_subdirectory(Platform)
add_subdirectory(Physics)
add_subdirectory(RHI) # Rendering Hardware Interface
add_subdirectory(Test)
add_subdirectory(Editor)
IF(NOT ANDROID AND NOT WA)
# add_subdirectory(Game)
ENDIF(NOT ANDROID AND NOT WA)

# ------------------------- Begin Generic CMake Variable Logging
# ------------------

# /*      C++ comment style not allowed   */

# current generator in use
message(STATUS "CMAKE_GENERATOR:         " ${CMAKE_GENERATOR})

# if you are building in-source, this is the same as CMAKE_SOURCE_DIR, otherwise this is the top level directory of your
# build tree
message(STATUS "CMAKE_BINARY_DIR:         " ${CMAKE_BINARY_DIR})

# if you are building in-source, this is the same as CMAKE_CURRENT_SOURCE_DIR, otherwise this is the directory where the
# compiled or generated files from the current CMakeLists.txt will go to
message(STATUS "CMAKE_CURRENT_BINARY_DIR: " ${CMAKE_CURRENT_BINARY_DIR})

# this is the directory, from which cmake was started, i.e. the top level source directory
message(STATUS "CMAKE_SOURCE_DIR:         " ${CMAKE_SOURCE_DIR})

# this is the directory where the currently processed CMakeLists.txt is located in
message(STATUS "CMAKE_CURRENT_SOURCE_DIR: " ${CMAKE_CURRENT_SOURCE_DIR})

# contains the full path to the top level directory of your build tree
message(STATUS "PROJECT_BINARY_DIR: " ${PROJECT_BINARY_DIR})

# contains the full path to the root of your project source directory, i.e. to the nearest directory where
# CMakeLists.txt contains the PROJECT() command
message(STATUS "PROJECT_SOURCE_DIR: " ${PROJECT_SOURCE_DIR})

# set this variable to specify a common place where CMake should put all executable files (instead of
# CMAKE_CURRENT_BINARY_DIR)
message(STATUS "EXECUTABLE_OUTPUT_PATH: " ${EXECUTABLE_OUTPUT_PATH})

# set this variable to specify a common place where CMake should put all libraries (instead of CMAKE_CURRENT_BINARY_DIR)
message(STATUS "LIBRARY_OUTPUT_PATH:     " ${LIBRARY_OUTPUT_PATH})

# tell CMake to search first in directories listed in CMAKE_MODULE_PATH when you use FIND_PACKAGE() or INCLUDE()
message(STATUS "CMAKE_MODULE_PATH: " ${CMAKE_MODULE_PATH})

# this is the complete path of the cmake which runs currently (e.g. /usr/local/bin/cmake)
message(STATUS "CMAKE_COMMAND: " ${CMAKE_COMMAND})

# this is the CMake installation directory
message(STATUS "CMAKE_ROOT: " ${CMAKE_ROOT})

# this is the filename including the complete path of the file where this variable is used.
message(STATUS "CMAKE_CURRENT_LIST_FILE: " ${CMAKE_CURRENT_LIST_FILE})

# this is linenumber where the variable is used
message(STATUS "CMAKE_CURRENT_LIST_LINE: " ${CMAKE_CURRENT_LIST_LINE})

# this is used when searching for include files e.g. using the FIND_PATH() command.
message(STATUS "CMAKE_INCLUDE_PATH: " ${CMAKE_INCLUDE_PATH})

# this is used when searching for libraries e.g. using the FIND_LIBRARY() command.
message(STATUS "CMAKE_LIBRARY_PATH: " ${CMAKE_LIBRARY_PATH})

# HOST the complete system name, e.g. "Linux-2.4.22", "FreeBSD-5.4-RELEASE" or "Windows 5.1"
message(STATUS "CMAKE_HOST_SYSTEM: " ${CMAKE_HOST_SYSTEM})

# the short system name, e.g. "Linux", "FreeBSD" or "Windows"
message(STATUS "CMAKE_HOST_SYSTEM_NAME: " ${CMAKE_HOST_SYSTEM_NAME})

# only the version part of CMAKE_SYSTEM
message(STATUS "CMAKE_HOST_SYSTEM_VERSION: " ${CMAKE_HOST_SYSTEM_VERSION})

# the processor name (e.g. "Intel(R) Pentium(R) M processor 2.00GHz")
message(STATUS "CMAKE_HOST_SYSTEM_PROCESSOR: " ${CMAKE_HOST_SYSTEM_PROCESSOR})

# TARGET the complete system name, e.g. "Linux-2.4.22", "FreeBSD-5.4-RELEASE" or "Windows 5.1"
message(STATUS "CMAKE_SYSTEM: " ${CMAKE_SYSTEM})

# the short system name, e.g. "Linux", "FreeBSD" or "Windows"
message(STATUS "CMAKE_SYSTEM_NAME: " ${CMAKE_SYSTEM_NAME})

# only the version part of CMAKE_SYSTEM
message(STATUS "CMAKE_SYSTEM_VERSION: " ${CMAKE_SYSTEM_VERSION})

# the processor name (e.g. "Intel(R) Pentium(R) M processor 2.00GHz")
message(STATUS "CMAKE_SYSTEM_PROCESSOR: " ${CMAKE_SYSTEM_PROCESSOR})

# is TRUE on all UNIX-like OS's, including Apple OS X and CygWin
message(STATUS "UNIX: " ${UNIX})

# is TRUE on Windows, including CygWin
message(STATUS "WIN32: " ${WIN32})

# is TRUE on Apple OS X
message(STATUS "APPLE: " ${APPLE})

# is TRUE when using the MinGW compiler in Windows
message(STATUS "MINGW: " ${MINGW})

# is TRUE on Windows when using the CygWin version of cmake
message(STATUS "CYGWIN: " ${CYGWIN})

# is TRUE on Windows when using a Borland compiler
message(STATUS "BORLAND: " ${BORLAND})

# is TRUE on PS4
message(STATUS "ORBIS: " ${ORBIS})

# Microsoft compiler
message(STATUS "MSVC: " ${MSVC})
message(STATUS "MSVC_IDE: " ${MSVC_IDE})
message(STATUS "MSVC60: " ${MSVC60})
message(STATUS "MSVC70: " ${MSVC70})
message(STATUS "MSVC71: " ${MSVC71})
message(STATUS "MSVC80: " ${MSVC80})
message(STATUS "CMAKE_COMPILER_2005: " ${CMAKE_COMPILER_2005})

# set this to true if you don't want to rebuild the object files if the rules have changed, but not the actual source
# files or headers (e.g. if you changed the some compiler switches)
message(STATUS "CMAKE_SKIP_RULE_DEPENDENCY: " ${CMAKE_SKIP_RULE_DEPENDENCY})

# since CMake 2.1 the install rule depends on all, i.e. everything will be built before installing. If you don't like
# this, set this one to true.
message(STATUS "CMAKE_SKIP_INSTALL_ALL_DEPENDENCY: " ${CMAKE_SKIP_INSTALL_ALL_DEPENDENCY})

# If set, runtime paths are not added when using shared libraries. Default it is set to OFF
message(STATUS "CMAKE_SKIP_RPATH: " ${CMAKE_SKIP_RPATH})

# set this to true if you are using makefiles and want to see the full compile and link commands instead of only the
# shortened ones
message(STATUS "CMAKE_VERBOSE_MAKEFILE: " ${CMAKE_VERBOSE_MAKEFILE})

# this will cause CMake to not put in the rules that re-run CMake. This might be useful if you want to use the generated
# build files on another machine.
message(STATUS "CMAKE_SUPPRESS_REGENERATION: " ${CMAKE_SUPPRESS_REGENERATION})

# A simple way to get switches to the compiler is to use ADD_DEFINITIONS(). But there are also two variables exactly for
# this purpose:

# the compiler flags for compiling C sources
message(STATUS "CMAKE_C_FLAGS: " ${CMAKE_C_FLAGS})
message(STATUS "CMAKE_C_FLAGS_DEBUG: " ${CMAKE_C_FLAGS_DEBUG})
message(STATUS "CMAKE_C_FLAGS_RELEASE: " ${CMAKE_C_FLAGS_RELEASE})
message(STATUS "CMAKE_C_FLAGS_RELWITHDEBINFO: " ${CMAKE_C_FLAGS_RELWITHDEBINFO})
message(STATUS "CMAKE_C_FLAGS_MINSIZEREL: " ${CMAKE_C_FLAGS_MINSIZEREL})

# the compiler flags for compiling C++ sources
message(STATUS "CMAKE_CXX_FLAGS: " ${CMAKE_CXX_FLAGS})
message(STATUS "CMAKE_CXX_FLAGS_DEBUG: " ${CMAKE_CXX_FLAGS_DEBUG})
message(STATUS "CMAKE_CXX_FLAGS_RELEASE: " ${CMAKE_CXX_FLAGS_RELEASE})
message(STATUS "CMAKE_CXX_FLAGS_RELWITHDEBINFO: " ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
message(STATUS "CMAKE_CXX_FLAGS_MINSIZEREL: " ${CMAKE_CXX_FLAGS_MINSIZEREL})

# Choose the type of build.  Example: SET(CMAKE_BUILD_TYPE Debug)
message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})

# if this is set to ON, then all libraries are built as shared libraries by default.
message(STATUS "BUILD_SHARED_LIBS: " ${BUILD_SHARED_LIBS})

# the compiler used for C files
message(STATUS "CMAKE_C_COMPILER: " ${CMAKE_C_COMPILER})

# the compiler used for C++ files
message(STATUS "CMAKE_CXX_COMPILER: " ${CMAKE_CXX_COMPILER})

# if the compiler is a variant of gcc, this should be set to 1
message(STATUS "CMAKE_COMPILER_IS_GNUCC: " ${CMAKE_COMPILER_IS_GNUCC})

# if the compiler is a variant of g++, this should be set to 1
message(STATUS "CMAKE_COMPILER_IS_GNUCXX : " ${CMAKE_COMPILER_IS_GNUCXX})

# the tools for creating libraries
message(STATUS "CMAKE_AR: " ${CMAKE_AR})
message(STATUS "CMAKE_RANLIB: " ${CMAKE_RANLIB})

message(STATUS "CMAKE_CROSSCOMPILING: " ${CMAKE_CROSSCOMPILING})

message(STATUS "TARGET_ARCH: " ${TARGET_ARCH})

message(STATUS "NBGE_EXTERNAL_LIBRARY_PATH: " ${NBGE_EXTERNAL_LIBRARY_PATH})

message(STATUS "XG_LIBRARY: " ${XG_LIBRARY})
message(STATUS "OPENDDL_LIBRARY: " ${OPENDDL_LIBRARY})
message(STATUS "OPENGEX_LIBRARY: " ${OPENGEX_LIBRARY})
MESSAGE(STATUS "ZLIB_LIBRARY: " ${ZLIB_LIBRARY})

message(STATUS "BULLET_COLLISION_LIBRARY: " ${BULLET_COLLISION_LIBRARY})
message(STATUS "BULLET_DYNAMICS_LIBRARY: " ${BULLET_DYNAMICS_LIBRARY})
message(STATUS "BULLET_LINEARMATH_LIBRARY: " ${BULLET_LINEARMATH_LIBRARY})

#
# MESSAGE( STATUS ": " ${} )

# ------------------------- End of Generic CMake Variable Logging
# ------------------
