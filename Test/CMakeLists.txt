add_executable(AssetLoaderTest AssetLoaderTest.cpp)
target_link_libraries(AssetLoaderTest Common)
add_test(NAME TEST_AssetLoader COMMAND AssetLoaderTest)

add_executable(GeomMathTest GeomMathTest.cpp)
target_link_libraries(GeomMathTest GeomMath)
add_test(NAME Test_GeomMath COMMAND GeomMathTest)
