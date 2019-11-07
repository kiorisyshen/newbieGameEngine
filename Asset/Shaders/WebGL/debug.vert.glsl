#version 300 es

layout(std140) uniform PerFrameConstants {
    mat4 worldMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
    vec4 camPos;
    int numLights;
}
pfc;

layout(location = 0) in vec4 a_inputPosition;
layout(location = 1) in vec4 a_inputColor;
out vec4 _entryPointOutput_color;

void main() {
    gl_Position             = pfc.projectionMatrix * pfc.viewMatrix * pfc.worldMatrix * a_inputPosition;
    _entryPointOutput_color = a_inputColor;
}
