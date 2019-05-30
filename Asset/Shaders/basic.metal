#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct PerFrameConstants
{
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3   lightPosition;
    float4   lightColor;
};

struct PerBatchConstants
{
    float4x4 objectLocalMatrix;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
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
    float3 L = normalize((v_43.viewMatrix * float4(v_43.lightPosition, 1.0f)).xyz - in.gl_Position.xyz);
    float3 R = normalize(2 * dot(L,N) * N - L );
    float3 V = normalize(in.gl_Position.xyz);
    float diffuse = dot(N, L);
    
//    float3 linearColor = diffuseMap.sample(samp0, in.uv).xyz * clamp(diffuse, 0.0f, 1.0f);
    if (v_24.diffuseColor.r < 0) {
//        return float4(0.03f, 0.03, 0.03, 1.0f) + float4(v_43.lightColor.rgb * clamp(linearColor + 0.01 * dot(R, V), 0.0f, 1.0f), 1.0f);
        return float4(0.1f, 0.1f, 0.1f, 1.0f) + float4(v_43.lightColor.rgb * diffuseMap.sample(samp0, in.uv).xyz * (diffuse*1.1 + 0.02 * dot(R, V)), 1.0f);
    } else {
//        return float4(float3(0.03f, 0.03, 0.03) + v_43.lightColor.rgb * v_24.diffuseColor.rgb * dot(N, L) + v_24.specularColor.rgb * pow(clamp(dot(R,V), 0.0f, 1.0f), v_24.specularPower), 1.0f);
        return float4(0.1f, 0.1f, 0.1f, 1.0f) + float4(v_43.lightColor.rgb * v_24.diffuseColor.rgb * (diffuse*1.1 + 0.02 * dot(R, V)), 1.0f);
//        return float4(0.03f, 0.03, 0.03, 1.0f) + float4(v_43.lightColor.rgb * clamp(diffuse + 0.01 * dot(R, V), 0.0f, 1.0f), 1.0f);
    }
}
