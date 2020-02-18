# newbieGameEngine
[![Build Status](https://travis-ci.org/kiorisyshen/newbieGameEngine.svg?branch=master)](https://travis-ci.org/kiorisyshen/newbieGameEngine)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/kiorisyshen/newbieGameEngine/master/LICENSE)

A simple repo for learning creating a game engine.
Reference: https://zhuanlan.zhihu.com/c_119702958

## Supported platform
- Mac OS (all tags)
- Web using WASM and WebGL2.0 (tag start with "wasm")
  - If you use safari, open develop setting and check WebGL2.0 support.

## Rendered results
- Basic Rendering (static shadow)
  - Tag: article_58
    ![Basic Rendering](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/01.png)

- Multiple light (spot, area, sun)
  - Tag: article_58
    [![Multilight](https://drive.google.com/uc?export=view&id=15w3rhaPC8022aVqWTW_ldtepl8s0FaOq)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/02.gif)

- Physics engine
  - Tag: article_39
    [![Physics](https://drive.google.com/uc?export=view&id=1vx8GdbRN0xlhQ_MyhmnmqPugHJmzqtSw)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/03.gif)

- Dynamic point light shadow
  - Tag: article_63
    [![PointShadow](https://drive.google.com/uc?export=view&id=1tNK0RL_u6f_zmPnc7ZOrC7P4TPW6TZ-S)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/04.gif)

- Physically Based Rendering (PBR)
  - Tag: article_67
    [![PBR](https://drive.google.com/uc?export=view&id=1rW00xHirjMsRqC-EQMnz0elCx8s3zN2h)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/05.gif)

- Terrain system (GPU Tessellation, Height map)
  - Tag: article_71
    [![TerrainSystem](https://drive.google.com/uc?export=view&id=1vD3wnQmp_zckhDU98fRYBzCyOvEI5OLZ)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/06.gif)

- Web Terrain (CPU Tessellation, WebAssembly)
  - Tag: wasm01
    [![WebAssembly](https://drive.google.com/uc?export=view&id=1uMcXebc5YOvTEURhgDAvwfD1hd7a3BOB)](https://github.com/kiorisyshen/newbieGameEngine/tree/master/result/07.png)

## Run code
### Prerequisite
- Build Third-party if given build script in External folder.
- ISPC
  - Download bin from [official](https://ispc.github.io/downloads.html) and place it to External/[your platform]/bin
  - Or build from source at External/src/ispc, build script is currently not provided.

### Build & Generate xcode project
You may refer build script write here: .vscode/tasks.json
