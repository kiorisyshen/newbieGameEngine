#!/bin/bash
mkdir -p build/opengex
cd build/opengex
cmake -DCMAKE_INSTALL_PREFIX=../../ ../../src/opengex
cmake --build . --config Release --target install
