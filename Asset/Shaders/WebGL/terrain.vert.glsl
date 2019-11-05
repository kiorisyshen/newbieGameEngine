#version 300 es

layout(std140) uniform TerrainPerPatchConstants {
    mat4 patchLocalMatrix;
}
_24;

layout(std140) uniform PerFrameConstants {
    mat4 worldMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
    vec4 camPos;
    int numLights;
}
_43;