#!/bin/bash
set -e
# source /Users/shen/Learning/emsdk/emsdk_env.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/External/$(uname -s)/lib
export EMSCRIPTEN=/Users/shen/Learning/emsdk/upstream/emscripten
mkdir -p build/WA/Debug
cd build/WA
rm -rf Debug
mkdir -p Debug
cd Debug
cmake -DCMAKE_TOOLCHAIN_FILE=../../../cmake/Emscripten.cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../../.. 
cmake --build . -- -j8
cd ../../..