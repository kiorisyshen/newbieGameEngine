#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct PerFrameConstants
{
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4   lightPosition;
    float4   lightColor;
};

struct PerBatchConstants
{
    float4x4 objectLocalMatrix;
    float4 diffuseColor;
    float4 specularColor;
};


struct basic_vert_main_out
{
    float4 normal [[user(locn0)]];
    float4 gl_Position [[position]];
    float2 uv;
};

struct basic_vert_main_in
{
    float3 inputPosition [[attribute(0)]];
    float3 inputNormal [[attribute(1)]];
    float2 inputUV [[attribute(2)]];
};

vertex basic_vert_main_out basic_vert_main(basic_vert_main_in in [[stage_in]], constant PerFrameConstants& v_43 [[buffer(10)]], constant PerBatchConstants& v_24 [[buffer(11)]])
{
    basic_vert_main_out out = {};
    
    float4x4 transM = v_43.worldMatrix * v_24.objectLocalMatrix;
    out.gl_Position = transM * float4(in.inputPosition, 1.0f);
    out.gl_Position = v_43.viewMatrix * out.gl_Position;
    out.gl_Position = v_43.projectionMatrix * out.gl_Position;
    
    out.normal = transM * float4(in.inputNormal, 0.0f);
    out.normal = v_43.viewMatrix * out.normal;
    out.uv.x = in.inputUV.x;
    out.uv.y = 1.0 - in.inputUV.y;
    return out;
}

fragment float4 basic_frag_main(basic_vert_main_out in [[stage_in]], texture2d<float> diffuseMap [[texture(0)]], sampler samp0 [[sampler(0)]], constant PerFrameConstants& v_43 [[buffer(10)]], constant PerBatchConstants& v_24 [[buffer(11)]])
{
    float3 N = normalize(in.normal.xyz);
    float3 L = normalize((v_43.viewMatrix * v_43.lightPosition).xyz - in.gl_Position.xyz);
    float cosTheta = clamp(dot(N, L), 0.0, 1.0);
    float3 R = normalize((N * (2.0 * dot(L, N))) - L);
    float3 V = normalize(-in.gl_Position.xyz);
    float3 specC = float3(0.800000011920928955078125 * pow(clamp(dot(R, V), 0.0, 1.0), 50.0));
    
    if (v_24.diffuseColor.r < 0) {
        float3 linearColor = diffuseMap.sample(samp0, in.uv).xyz * cosTheta;
        return float4(0.05f, 0.05f, 0.05f, 1.0f) + float4(v_43.lightColor.rgb * (linearColor + specC), 1.0f);
    } else {
        return float4(0.05f, 0.05f, 0.05f, 1.0f) + float4(v_43.lightColor.rgb * (v_24.diffuseColor.rgb * cosTheta + specC), 1.0f);
    }
}
