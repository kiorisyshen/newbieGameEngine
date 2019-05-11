# newbieGameEngine
A simple repo for learning creating a game engine. Reference: https://zhuanlan.zhihu.com/c_119702958
Currently only support MacOS

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