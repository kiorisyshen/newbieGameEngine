add_library(PlatformInterface 
            EmptyApplication.cpp
)
add_library(newbieGameEngine EmptyApplicationConfig.cpp)
target_link_libraries(newbieGameEngine 
            Common 
            EmptyRHI
            PlatformInterface
)
