## D2D
### Release
```
clang -l user32.lib -l ole32.lib -l d2d1.lib -o helloengine_d2d.exe helloengine_d2d.cpp
```

### Debug
```
clang-cl -c -Z7 -o helloengine_d2d.obj helloengine_d2d.cpp
link -debug user32.lib ole32.lib d2d1.lib helloengine_d2d.obj
devenv /debug helloengine_d2d.exe
```

## D3D
### Compile shader
```
fxc /T vs_5_0 /Zi /Fo copy.vso copy.vs
fxc /T ps_5_0 /Zi /Fo copy.pso copy.ps
```

### Release
```
clang -l user32.lib -l d3d11.lib -l d3dcompiler.lib -o helloengine_d3d.exe helloengine_d3d.cpp
```

### Debug
```
clang-cl -c -Z7 -o helloengine_d3d.obj helloengine_d3d.cpp
link -debug user32.lib d3d11.lib d3dcompiler.lib helloengine_d3d.obj
devenv /debug helloengine_d3d.exe
```

### D3D12
```
cl /EHsc helloengine_d3d12.cpp user32.lib d3d12.lib dxgi.lib d3dcompiler.lib
```