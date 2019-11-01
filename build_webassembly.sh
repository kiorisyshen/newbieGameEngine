#!/bin/bash
set -e
# source /Users/shen/Learning/emsdk/emsdk_env.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/External/$(uname -s)/lib
mkdir -p build/WA/Debug
rm -rf build/WA/Debug/*
cd build/WA/Debug
cmake -DCMAKE_TOOLCHAIN_FILE=../../../cmake/Emscripten.cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../../.. 
cmake --build . -- -j8
cd ../../..