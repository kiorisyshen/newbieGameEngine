#version 300 es
precision mediump float;
precision highp int;

struct basic_vert_output {
    highp vec4 pos;
    highp vec4 normal;
    highp vec4 normal_world;
    highp vec4 v;
    highp vec4 v_world;
    highp vec2 uv;
};

struct Light {
    highp mat4 lightVP;                   // 64 bytes
    highp vec4 lightPosition;             // 16 bytes
    highp vec4 lightColor;                // 16 bytes
    highp vec4 lightDirection;            // 16 bytes
    float lightDistAttenCurveParams[8];   // 32 bytes
    float lightAngleAttenCurveParams[8];  // 32 bytes
    highp vec2 lightSize;                 // 8 bytes
    int lightDistAttenCurveType;          // 4 bytes
    int lightAngleAttenCurveType;         // 4 bytes
    highp float lightIntensity;           // 4 bytes
    int lightType;                        // 4 bytes
    int lightCastShadow;                  // 4 bytes
    int lightShadowMapIndex;              // 4 bytes
    // Above is 208 bytes

    // Fill bytes to align to 256 bytes (Metal required)
    float padding[12];  // 48 bytes
};

layout(std140) uniform PerFrameConstants {
    highp mat4 worldMatrix;
    highp mat4 viewMatrix;
    highp mat4 projectionMatrix;
    highp vec4 camPos;
    int numLights;
}
_280;

layout(std140) uniform LightInfo {
    Light lights[100];
}
_677;

uniform highp sampler2D SPIRV_Cross_CombineddiffuseMapsamp0;
uniform highp sampler2DArray SPIRV_Cross_Combinedskyboxsamp0;

in highp vec4 _entryPointOutput_normal;
in highp vec4 _entryPointOutput_normal_world;
in highp vec4 _entryPointOutput_v;
in highp vec4 _entryPointOutput_v_world;
in highp vec2 _entryPointOutput_uv;
layout(location = 0) out highp vec4 _entryPointOutput;

void main() {
    basic_vert_output _entryPointOutput_1;
    _entryPointOutput_1.pos          = gl_FragCoord;
    _entryPointOutput_1.normal       = _entryPointOutput_normal;
    _entryPointOutput_1.normal_world = _entryPointOutput_normal_world;
    _entryPointOutput_1.v            = _entryPointOutput_v;
    _entryPointOutput_1.v_world      = _entryPointOutput_v_world;
    _entryPointOutput_1.uv           = _entryPointOutput_uv;
    basic_vert_output param          = _entryPointOutput_1;
    _entryPointOutput                = _basic_frag_main(param);

    vec3 N        = normalize(_entryPointOutput_normal.xyz);
    vec3 L        = normalize((viewMatrix * vec4(_677[0].lightPosition, 1.0f)).xyz - _entryPointOutput_v.xyz);
    vec3 R        = normalize(2 * dot(L, N) * N - L);
    vec3 V        = normalize(_entryPointOutput_v.xyz);
    float diffuse = dot(N, L);
    outputColor   = vec4(_677[0].lightColor.rgb * clamp(diffuse + 0.01 * dot(R, V), 0.0f, 1.0f), 1.0f);
}
