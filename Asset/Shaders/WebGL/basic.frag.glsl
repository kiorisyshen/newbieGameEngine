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

// struct Light {
//     highp mat4 lightVP;
//     highp vec4 lightPosition;
//     highp vec4 lightColor;
//     highp vec4 lightDirection;
//     float lightDistAttenCurveParams[8];
//     float lightAngleAttenCurveParams[8];
//     highp vec2 lightSize;
//     int lightDistAttenCurveType;
//     int lightAngleAttenCurveType;
//     float lightIntensity;
//     int lightType;
//     int lightCastShadow;
//     int lightShadowMapIndex;
//     float padding[12];
// };

layout(std140) uniform PerFrameConstants {
    highp mat4 worldMatrix;
    highp mat4 viewMatrix;
    highp mat4 projectionMatrix;
    highp vec4 camPos;
    int numLights;
}
_280;

// layout(std140) uniform LightInfo {
//     Light lights[100];
// }
// _677;

uniform highp sampler2D SPIRV_Cross_CombineddiffuseMapsamp0;
uniform highp sampler2DArray SPIRV_Cross_Combinedskyboxsamp0;

in highp vec4 _entryPointOutput_normal;
in highp vec4 _entryPointOutput_normal_world;
in highp vec4 _entryPointOutput_v;
in highp vec4 _entryPointOutput_v_world;
in highp vec2 _entryPointOutput_uv;
layout(location = 0) out highp vec4 _entryPointOutput;

void main() {
    // vec3 N            = normalize(_entryPointOutput_normal.xyz);
    // vec3 L            = normalize((_280.viewMatrix * vec4(_677.lights[0].lightPosition.xyz, 1.0f)).xyz - _entryPointOutput_v.xyz);
    // float NdotL       = dot(N, L);
    // vec3 R            = normalize((NdotL * 2.0f) * N - L);
    // vec3 V            = normalize(_entryPointOutput_v.xyz);
    // float diffuse     = NdotL;
    // _entryPointOutput = vec4(_677.lights[0].lightColor.rgb * clamp(diffuse + 0.01 * dot(R, V), 0.0f, 1.0f), 1.0f);
    _entryPointOutput = vec4(0.4, 0.8, 0.2, 1.0);
}
