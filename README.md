# newbieGameEngine
A simple repo for learning creating a game engine. Reference: https://zhuanlan.zhihu.com/c_119702958
Currently only support MacOS

# Pre-requiresite
- Download ISPC compiler from: https://ispc.github.io/downloads.html
  or build from source at External/src/ispc
- Build crossguid at External/src/crossguid using:
    ```shell
    cd External
    ./build_crossguid.sh
    ```
    Then copy External/install/* into your platform (eg. External/Darwin/)


# Build
```shell
mkdir build
cd build
cmake ..
cmake --build . --config Release --clean-first
```

For runing test:
```shell
cmake --build . --config Debug --target test
```

## Generate xcode project
```shell
mkdir build
cd build
cmake -G Xcode ..
```