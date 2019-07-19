# Empty
if(${CMAKE_SYSTEM_NAME} MATCHES Orbis)

elseif(${CMAKE_SYSTEM_NAME} MATCHES PSP2)

else()
  add_subdirectory(Empty)
  if(${WIN32})
    # Windows specific code
    add_subdirectory(D2d)
    add_subdirectory(D3d)
  endif(${WIN32})
  if(${APPLE})
    # Darwin specific code
    add_subdirectory(Metal)
  endif(${APPLE})
  # add_subdirectory(OpenGL)
endif()
