#!/bin/bash
mkdir -p build/zlib
cd build/zlib
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/zlib
cmake --build . --config release --target install

