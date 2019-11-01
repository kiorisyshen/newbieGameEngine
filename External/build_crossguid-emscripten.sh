#!/bin/bash
set -e
mkdir -p build/crossguid
rm -rf build/crossguid/*
pushd build/crossguid
cmake -DCMAKE_TOOLCHAIN_FILE=../../../cmake/Emscripten.cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/crossguid
cmake --build . --config debug --target install
popd

