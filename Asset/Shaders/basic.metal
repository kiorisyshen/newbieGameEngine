#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct PerFrameConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 worldMatrix;
};

struct basic_vert_main_out
{
    float4 _entryPointOutput_normal [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct basic_vert_main_in
{
    float3 inputPosition [[attribute(0)]];
    float3 inputNormal [[attribute(1)]];
};

vertex basic_vert_main_out basic_vert_main(basic_vert_main_in in [[stage_in]], constant PerFrameConstants& v_43 [[buffer(10)]])
{
    basic_vert_main_out out = {};
    
    out.gl_Position = v_43.worldMatrix * float4(in.inputPosition, 1.0f);
    out.gl_Position = v_43.viewMatrix * out.gl_Position;
    out.gl_Position = v_43.projectionMatrix * out.gl_Position;
    
    out._entryPointOutput_normal = v_43.worldMatrix * float4(in.inputNormal, 0.0f);
    out._entryPointOutput_normal = v_43.viewMatrix * out._entryPointOutput_normal;
    
    return out;
}

fragment float4 fragmentShader(basic_vert_main_out in [[stage_in]])
{
    // Return the interpolated color.
    return float4(1.0, 1.0, 1.0, 1.0);
}
