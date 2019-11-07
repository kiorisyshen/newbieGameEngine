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
    ![Basic Rendering](https://drive.google.com/uc?export=view&id=1k3x-EZGFFttldQu7D8EYryGH_NHkHebQ)

- Multiple light (spot, area, sun)
  - Tag: article_58
    [![Multilight](https://drive.google.com/uc?export=view&id=15w3rhaPC8022aVqWTW_ldtepl8s0FaOq)](https://drive.google.com/open?id=1SIQshdBfo_Ho2N-zZkskg9QhKWQ5aqhQ)

- Physics engine
  - Tag: article_39
    [![Physics](https://drive.google.com/uc?export=view&id=1vx8GdbRN0xlhQ_MyhmnmqPugHJmzqtSw)](https://drive.google.com/open?id=1P_DmRoyqiS7sFqA8l56mZRLJaxk5m9em)

- Dynamic point light shadow
  - Tag: article_63
    [![PointShadow](https://drive.google.com/uc?export=view&id=1tNK0RL_u6f_zmPnc7ZOrC7P4TPW6TZ-S)](https://drive.google.com/open?id=1nuEEFtn27smufeKDN6ocoMEd-OqUiUWA)

- Physically Based Rendering (PBR)
  - Tag: article_67
    [![PBR](https://drive.google.com/uc?export=view&id=1rW00xHirjMsRqC-EQMnz0elCx8s3zN2h)](https://drive.google.com/open?id=1V6HMHp5GtHTAbPU4upRdrPZxempTNf-h)

- Terrain system (GPU Tessellation, Height map)
  - Tag: article_71
    [![TerrainSystem](https://drive.google.com/uc?export=view&id=1vD3wnQmp_zckhDU98fRYBzCyOvEI5OLZ)](https://drive.google.com/open?id=1mUSXVqMNk4ociX8iN9peph6-5iJvDjhy)

- Web Terrain (CPU Tessellation, WebAssembly)
  - Tag: wasm01
    [![WebAssembly](https://drive.google.com/uc?export=view&id=1uMcXebc5YOvTEURhgDAvwfD1hd7a3BOB)](https://drive.google.com/open?id=1uMcXebc5YOvTEURhgDAvwfD1hd7a3BOB)

## Run code
### Pre-requiresite
- Build Third-party if given build script in External folder.
- ISPC
  - Download bin from [official](https://ispc.github.io/downloads.html) and place it to External/[your platform]/bin
  - Or build from source at External/src/ispc, build script is currently not provided.

### Build & Generate xcode project
You may refer build script write here: .vscode/tasks.json
