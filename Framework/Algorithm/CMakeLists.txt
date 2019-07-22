add_library(Algorithm quickhull.cpp)
target_include_directories(Algorithm PUBLIC GeomMath)
target_link_libraries(Algorithm PUBLIC GeomMath)
