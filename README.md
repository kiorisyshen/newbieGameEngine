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
    ![Basic Rendering](/results/01.png)

- Multiple light (spot, area, sun)
  - Tag: article_58
    [![Multilight](/results/02.gif)](https://drive.google.com/open?id=1SIQshdBfo_Ho2N-zZkskg9QhKWQ5aqhQ)

- Physics engine
  - Tag: article_39
    [![Physics](/results/03.gif)](https://drive.google.com/open?id=1P_DmRoyqiS7sFqA8l56mZRLJaxk5m9em)

- Dynamic point light shadow
  - Tag: article_63
    [![PointShadow](/results/04.gif)](https://drive.google.com/open?id=1nuEEFtn27smufeKDN6ocoMEd-OqUiUWA)

- Physically Based Rendering (PBR)
  - Tag: article_67
    [![PBR](/results/05.gif)](https://drive.google.com/open?id=1V6HMHp5GtHTAbPU4upRdrPZxempTNf-h)

- Terrain system (GPU Tessellation, Height map)
  - Tag: article_71
    [![TerrainSystem](/results/06.gif)](https://drive.google.com/open?id=1mUSXVqMNk4ociX8iN9peph6-5iJvDjhy)

- Web Terrain (CPU Tessellation, WebAssembly)
  - Tag: wasm01
    [![WebAssembly](/results/07.png)](https://drive.google.com/open?id=1uMcXebc5YOvTEURhgDAvwfD1hd7a3BOB)

## Run code
### Prerequisite
- Build Third-party if given build script in External folder.
- ISPC
  - Download bin from [official](https://ispc.github.io/downloads.html) and place it to External/[your platform]/bin
  - Or build from source at External/src/ispc, build script is currently not provided.

### Build & Generate xcode project
You may refer build script write here: .vscode/tasks.json
