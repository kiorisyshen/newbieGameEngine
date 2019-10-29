set(TEST_CASES AssetLoaderTest GeomMathTest ColorSpaceConversionTest
               JpegParserTest DdsParserTest HdrParserTest TgaParserTest
               NumericalMethodsTest BezierCubic1DTest QuickhullTest GjkTest LinearInterpolateTest QRDecomposeTest PolarDecomposeTest
               #RasterizationTest SceneObjectTest BulletTest OgexParserTest SceneLoadingTest PngParserTest AnimationTest
        )

foreach(TEST_CASE IN LISTS TEST_CASES)
    add_executable(${TEST_CASE} ${TEST_CASE}.cpp)
    target_link_libraries(${TEST_CASE} Common)
    add_test(NAME TEST_${TEST_CASE} COMMAND ${TEST_CASE})
endforeach(TEST_CASE)

# target_link_libraries(BulletTest BulletPhysics)

IF(WA)
add_custom_target(PackageAsset ALL
    python $ENV{EMSCRIPTEN}/tools/file_packager.py ${CMAKE_CURRENT_BINARY_DIR}/Asset.data
        --lz4
        --no-heap-copy
        --js-output=${CMAKE_CURRENT_BINARY_DIR}/Asset.preload.js
        --preload Asset/Textures/eye.png
                  Asset/Textures/hdr/PaperMill_posx.dds
                  Asset/Textures/hdr/PaperMill_E_3k.hdr
                  Asset/Textures/huff_simple0.jpg
                  Asset/Textures/interior_lod0.tga
                  Asset/Scene/splash.ogex
                  Asset/Shaders
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    VERBATIM
        )
ENDIF(WA)