cmake_minimum_required (VERSION 3.1)

set (CMAKE_C_STANDARD 11)
set (CMAKE_CXX_STANDARD 11)

# the short system name, e.g. "Linux", "FreeBSD" or "Windows"
MESSAGE( STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")

project (newbieGameEngine)
include_directories("${PROJECT_SOURCE_DIR}/Framework/Common")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Interface")
# include_directories("${PROJECT_SOURCE_DIR}/Platform/${CMAKE_SYSTEM_NAME}/")
include_directories("${PROJECT_SOURCE_DIR}/RHI")
include_directories("${PROJECT_SOURCE_DIR}/Platform/Empty/")

# find_library(XG_LIBRARY xg PATHS ${MYGE_EXTERNAL_LIBRARY_PATH})
# find_library(OPENDDL_LIBRARY OpenDDL PATHS ${MYGE_EXTERNAL_LIBRARY_PATH})
# find_library(OPENGEX_LIBRARY OpenGEX PATHS ${MYGE_EXTERNAL_LIBRARY_PATH})
# include(PlatformDependencies)

add_subdirectory(Framework)
add_subdirectory(Platform)
add_subdirectory(RHI) # Rendering Hardware Interface
# add_subdirectory(Empty)