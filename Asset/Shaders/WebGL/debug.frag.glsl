#version 300 es

precision mediump float;
precision highp int;

in highp vec4 _entryPointOutput_color;
layout(location = 0) out highp vec4 _entryPointOutput;

void main() {
    _entryPointOutput = _entryPointOutput_color;
}
