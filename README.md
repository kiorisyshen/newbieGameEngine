# newbieGameEngine
[![Build Status](https://travis-ci.org/kiorisyshen/newbieGameEngine.svg?branch=master)](https://travis-ci.org/kiorisyshen/newbieGameEngine)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/kiorisyshen/newbieGameEngine/master/LICENSE)

A simple repo for learning creating a game engine. Reference: https://zhuanlan.zhihu.com/c_119702958

## Supported platform
- Mac OS (all tags)
- Web using WASM and WebGL2.0 (tag start with "wasm")
  - If you use safari, open develop setting and check WebGL2.0 support.

## Rendered results
<iframe src="https://drive.google.com/file/d/1P_DmRoyqiS7sFqA8l56mZRLJaxk5m9em/preview" width="640" height="480"></iframe>

## Run code
### Pre-requiresite
- Build Third-party if given build script in External folder.
- ISPC
  - Download bin from [official](https://ispc.github.io/downloads.html) and place it to External/[your platform]/bin
  - Or build from source at External/src/ispc, build script is currently not provided.

### Build & Generate xcode project
You may refer build script write here: .vscode/tasks.json
