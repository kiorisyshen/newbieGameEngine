cmake_minimum_required (VERSION 3.1)

set (CMAKE_C_STANDARD 11)
set (CMAKE_CXX_STANDARD 11)

project (newbieGameEngine)

set(NBGE_EXTERNAL_ROOT ${PROJECT_SOURCE_DIR}/External/${CMAKE_SYSTEM_NAME}/)
set(NBGE_EXTERNAL_INCLUDE_PATH ${NBGE_EXTERNAL_ROOT}include/)
set(NBGE_EXTERNAL_LIBRARY_PATH ${NBGE_EXTERNAL_ROOT}lib/)

include_directories("${PROJECT_SOURCE_DIR}/Framework/Common/")
include_directories("${PROJECT_SOURCE_DIR}/Framework/Interface/")
include_directories("${PROJECT_SOURCE_DIR}/Framework/GeomMath/")
include_directories("${PROJECT_SOURCE_DIR}/RHI/")
include_directories("${PROJECT_SOURCE_DIR}/Platform/Darwin/")
include(CTest) # use --target test to run test cases
               # useful flag:
               #    --clean-first
include_directories("${NBGE_EXTERNAL_INCLUDE_PATH}")

find_library(XG_LIBRARY crossguid PATHS ${NBGE_EXTERNAL_LIBRARY_PATH})

add_subdirectory(Framework)
add_subdirectory(Platform)
add_subdirectory(RHI) # Rendering Hardware Interface

# the short system name, e.g. "Linux", "FreeBSD" or "Windows"
MESSAGE( STATUS "CMAKE_SYSTEM_NAME: " ${CMAKE_SYSTEM_NAME} )

MESSAGE( STATUS "XG_LIBRARY: " ${XG_LIBRARY} )