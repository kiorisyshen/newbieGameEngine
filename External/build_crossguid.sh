#!/bin/bash
git submodule update --init src/crossguid
mkdir -p build/crossguid
cd build/crossguid
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/crossguid
cmake --build . --config Release --target install
