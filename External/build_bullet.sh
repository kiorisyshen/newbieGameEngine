#!/bin/sh
mkdir -p build/bullet
rm -rf build/bullet/*
cd build/bullet
cmake -DCMAKE_INSTALL_PREFIX=../../`uname -s`/ -DCMAKE_INSTALL_RPATH=../../`uname -s`/ -DBUILD_SHARED_LIBS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_OPENGL3_DEMOS=OFF -DBUILD_CPU_DEMOS=OFF -DBUILD_PYBULLET=OFF -DUSE_DOUBLE_PRECISION=ON -DBUILD_EXTRAS=OFF -DBUILD_UNIT_TESTS=OFF -DCMAKE_BUILD_TYPE=RELEASE ../../src/bullet3 || exit 1
cmake --build . --config release --target install
echo "Completed build of Bullet."

