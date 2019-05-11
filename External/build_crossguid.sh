#!/bin/bash
mkdir -p build/crossguid
cd build/crossguid
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/crossguid
cmake --build . --config Release

# install
cd -
mkdir -p install/include/crossguid
mkdir -p install/lib
cp build/crossguid/libxg.a install/lib
cp src/crossguid/Guid.hpp install/include/crossguid