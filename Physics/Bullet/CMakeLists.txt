find_library(BULLET_COLLISION_LIBRARY
             NAMES BulletCollision
             PATHS ${NBGE_EXTERNAL_LIBRARY_PATH}
             NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
find_library(BULLET_DYNAMICS_LIBRARY
             NAMES BulletDynamics
             PATHS ${NBGE_EXTERNAL_LIBRARY_PATH}
             NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
find_library(BULLET_LINEARMATH_LIBRARY NAMES LinearMath PATHS ${NBGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH
                                                                                            NO_SYSTEM_ENVIRONMENT_PATH)

if(ORBIS)
    find_library(SCE_POSIX_LIBRARY NAMES ScePosix_stub_weak PATHS "$ENV{SCE_ORBIS_SDK_DIR}/target/lib")
endif(ORBIS)

add_library(BulletPhysics BulletPhysicsManager.cpp)
target_include_directories(BulletPhysics PUBLIC GeomMath)
target_link_libraries(BulletPhysics
                      GeomMath
                      ${BULLET_DYNAMICS_LIBRARY}
                      ${BULLET_COLLISION_LIBRARY}
                      ${BULLET_LINEARMATH_LIBRARY})
if(ORBIS)
    target_link_libraries(BulletPhysics ${SCE_POSIX_LIBRARY})
endif(ORBIS)
