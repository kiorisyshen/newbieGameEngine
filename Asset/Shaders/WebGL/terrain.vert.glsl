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

uniform highp sampler2D TerrainHeightMapsamp0;

layout(location = 0) in vec4 a_inputPosition;

void main() {
    vec4 v_world = pfc.worldMatrix * tppc.patchLocalMatrix * a_inputPosition;
    vec2 uv      = v_world.xy / 80.0;
    uv += (0.5, 0.5);
    float height = texture(TerrainHeightMapsamp0, uv).x;
    height       = height * 10.0;

    v_world.z = 0.0;
    if (v_world.x > 0.0) {
        v_world.z = height;
    }

    gl_Position = pfc.projectionMatrix * pfc.viewMatrix * v_world;
}