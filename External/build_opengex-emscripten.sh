#!/bin/bash
set -e
mkdir -p build/opengex
pushd build/opengex
cmake -DCMAKE_TOOLCHAIN_FILE=../../../cmake/Emscripten.cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/opengex
cmake --build . --config release --target install
popd

