# newbieGameEngine
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/kiorisyshen/newbieGameEngine/master/LICENSE)

A simple repo for learning creating a game engine. Reference: https://zhuanlan.zhihu.com/c_119702958
Currently only support MacOS

Original reference repo: https://github.com/netwarm007/GameEngineFromScratch

# Pre-requiresite
- ISPC
  - Download bin from [official](https://ispc.github.io/downloads.html) and place it to External/[your platform]/bin
  - Or build from source at External/src/ispc
- Crossguid
  - Build crossguid at External/src/crossguid using:
    ```shell
    cd External
    ./build_crossguid.sh
    ```
- OpenGEX
  - Build OpenGEX at External/src/opengex using:
    ```shell
    cd External
    ./build_opengex.sh
    ```

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
