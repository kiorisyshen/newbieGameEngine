#!/bin/bash
mkdir -p build/crossguid
rm -rf build/crossguid/*
cd build/crossguid
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/crossguid
cmake --build . --config Release --target install
