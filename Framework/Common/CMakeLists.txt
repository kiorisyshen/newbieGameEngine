add_library(Common
            AnimationManager.cpp
            AssetLoader.cpp
            BaseApplication.cpp
            DebugManager.cpp
            GraphicsManager.cpp
            InputManager.cpp
            Image.cpp
            MemoryManager.cpp
            Scene.cpp
            SceneManager.cpp
            SceneObject.cpp
            SceneObjectAnimation.cpp
            SceneObjectMesh.cpp
            SceneObjectTrack.cpp
            main.cpp)

target_link_libraries(Common
                      Algorithm
                      DrawPass
                      DispatchPass
                      Geometries
                      GeomMath
                      ${OPENGEX_LIBRARY}
                      ${OPENDDL_LIBRARY}
                      ${XG_LIBRARY}
                      ${ZLIB_LIBRARY})

__add_xg_platform_dependencies(Common)

# if(WIN32) add_definitions(-DGUID_WINDOWS) elseif(APPLE) add_definitions(-DGUID_CFUUID) set(CMAKE_CXX_FLAGS
# "${CMAKE_CXX_FLAGS} -Wall -pedantic") elseif(ANDROID) target_compile_definitions(Common PRIVATE GUID_ANDROID)
# elseif(ORBIS) # nothing here else(WIN32) find_package(Libuuid REQUIRED) if (NOT LIBUUID_FOUND) message(FATAL_ERROR
# "You might need to run 'sudo apt-get install uuid-dev' or similar") endif()
# include_directories(${LIBUUID_INCLUDE_DIR}) add_definitions(-DGUID_LIBUUID) set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}
# -Wall -pedantic") endif()
