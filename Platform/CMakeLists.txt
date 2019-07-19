if(${WIN32})
  # Windows specific code
  add_subdirectory(Windows)
elseif(${UNIX})
  if(${APPLE})
    # Apple specific code
    add_subdirectory(Darwin)
  elseif(${ANDROID})
    add_subdirectory(Android)
  else(${APPLE})
    # Linux specific code
    add_subdirectory(Linux)
  endif(${APPLE})
elseif(${ORBIS})
  add_subdirectory(Orbis)
else()
  # Empty
  add_subdirectory(Empty)
endif(${WIN32})
