#!/bin/bash
mkdir -p build/opengex
rm -rf build/opengex/*
cd build/opengex
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/opengex
cmake --build . --config Release --target install
