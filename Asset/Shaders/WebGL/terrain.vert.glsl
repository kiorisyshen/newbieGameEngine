#version 300 es

layout(std140) uniform TerrainPerPatchConstants {
    mat4 patchLocalMatrix;
}
tppc;

layout(std140) uniform PerFrameConstants {
    mat4 worldMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
    vec4 camPos;
    int numLights;
}
pfc;

layout(location = 0) in vec4 a_inputPosition;

void main() {
    gl_Position = pfc.projectionMatrix * pfc.viewMatrix * pfc.worldMatrix * tppc.patchLocalMatrix * a_inputPosition;
}