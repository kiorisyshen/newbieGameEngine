add_executable(AssetLoaderTest AssetLoaderTest.cpp)
target_link_libraries(AssetLoaderTest Common)
add_test(NAME TEST_AssetLoader COMMAND AssetLoaderTest)

add_executable(GeomMathTest GeomMathTest.cpp)
target_link_libraries(GeomMathTest GeomMath)
add_test(NAME Test_GeomMath COMMAND GeomMathTest)

add_executable(ColorSpaceConversionTest ColorSpaceConversionTest.cpp)
target_link_libraries(ColorSpaceConversionTest GeomMath)
add_test(NAME Test_ColorSpaceConversion COMMAND ColorSpaceConversionTest)

add_executable(OgexParserTest OgexParserTest.cpp)
target_link_libraries(OgexParserTest Common)
__add_xg_platform_dependencies(OgexParserTest)
add_test(NAME TEST_OgexParser COMMAND OgexParserTest)

add_executable(JpegParserTest JpegParserTest.cpp)
target_link_libraries(JpegParserTest Common)
add_test(NAME TEST_JpegParser COMMAND JpegParserTest)

add_executable(PngParserTest PngParserTest.cpp)
target_link_libraries(PngParserTest Common)
add_test(NAME TEST_PngParser COMMAND PngParserTest)

add_executable(TgaParserTest TgaParserTest.cpp)
target_link_libraries(TgaParserTest Common)
add_test(NAME TEST_TgaParser COMMAND TgaParserTest)

# add_executable(SceneObjectTest SceneObjectTest.cpp)
# target_link_libraries(SceneObjectTest Common ${XG_LIBRARY})
# __add_xg_platform_dependencies(SceneObjectTest) add_test(NAME TEST_SceneObject
# COMMAND SceneObjectTest)

add_executable(SceneLoadingTest SceneLoadingTest.cpp)
target_link_libraries(SceneLoadingTest Common)
__add_xg_platform_dependencies(SceneLoadingTest)
add_test(NAME TEST_SceneLoading COMMAND SceneLoadingTest)

add_executable(AnimationTest AnimationTest.cpp)
target_link_libraries(AnimationTest Common)
add_test(NAME TEST_Animation COMMAND AnimationTest)

add_executable(BulletTest BulletTest.cpp)
target_link_libraries(BulletTest
                      ${BULLET_DYNAMICS_LIBRARY}
                      ${BULLET_COLLISION_LIBRARY}
                      ${BULLET_LINEARMATH_LIBRARY})
add_test(NAME TEST_Bullet COMMAND BulletTest)

add_executable(NumericalMethodsTest NumericalMethodsTest.cpp)
add_test(NAME TEST_NumericalMethods COMMAND NumericalMethodsTest)

add_executable(BezierCubic1DTest BezierCubic1DTest.cpp)
add_test(NAME TEST_BezierCubic1D COMMAND BezierCubic1DTest)
target_include_directories(BezierCubic1DTest PUBLIC GeomMath)
target_link_libraries(BezierCubic1DTest GeomMath)

add_executable(QuickhullTest QuickhullTest.cpp)
target_link_libraries(QuickhullTest
                      Algorithm
                      Geometries
                      GeomMath)
add_test(NAME TEST_Quickhull COMMAND QuickhullTest)

add_executable(GjkTest GjkTest.cpp)
target_link_libraries(GjkTest
                      Algorithm
                      Geometries
                      GeomMath)
add_test(NAME TEST_Gjk COMMAND GjkTest)

add_executable(LinearInterpolateTest LinearInterpolateTest.cpp)
target_link_libraries(LinearInterpolateTest Algorithm GeomMath)
add_test(NAME TEST_LinearInterpolate COMMAND LinearInterpolateTest)

add_executable(QRDecomposeTest QRDecomposeTest.cpp)
target_link_libraries(QRDecomposeTest Algorithm GeomMath)
add_test(NAME TEST_QRDecompose COMMAND QRDecomposeTest)

add_executable(PolarDecomposeTest PolarDecomposeTest.cpp)
target_link_libraries(PolarDecomposeTest Algorithm GeomMath)
add_test(NAME TEST_PolarDecompose COMMAND PolarDecomposeTest)
