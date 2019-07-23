#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct PerFrameConstants {
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4   lightPosition;
    float4   lightColor;
    float4   ambientColor;                   // 16 bytes
    float4   lightDirection;                 // 16 bytes
    float4   lightDistAttenCurveParams[2];   // 32 bytes
    float4   lightAngleAttenCurveParams[2];  // 32 bytes
    int      lightDistAttenCurveType;        // 4 bytes
    int      lightAngleAttenCurveType;       // 4 bytes
    float    lightIntensity;                 // 4 bytes
};

struct PerBatchConstants {
    float4x4 objectLocalMatrix;
    float4   diffuseColor;
    float4   specularColor;
    float    specularPower;
};

struct basic_vert_main_out {
    float4 normal [[user(locn0)]];
    float4 normal_world [[user(locn1)]];
    float4 v [[user(locn2)]];
    float4 v_world [[user(locn3)]];
    float2 uv [[user(locn4)]];
    float4 gl_Position [[position]];
};

struct basic_vert_main_in {
    float3 inputPosition [[attribute(0)]];
    float3 inputNormal [[attribute(1)]];
    float2 inputUV [[attribute(2)]];
};

// Implementation of an array copy function to cover GLSL's ability to copy an array via assignment.
template <typename T, uint N>
void spvArrayCopy(thread T (&dst)[N], thread const T (&src)[N])
{
    for (uint i = 0; i < N; dst[i] = src[i], i++)
        ;
}

// An overload for constant arrays.
template <typename T, uint N>
void spvArrayCopyConstant(thread T (&dst)[N], constant T (&src)[N])
{
    for (uint i = 0; i < N; dst[i] = src[i], i++)
        ;
}

float linear_interpolate(thread const float& t, thread const float& begin, thread const float& end)
{
    if (t < begin) {
        return 1.0;
    } else {
        if (t > end) {
            return 0.0;
        } else {
            return (end - t) / (end - begin);
        }
    }
}

float apply_atten_curve(thread const float& dist, thread const int& atten_curve_type, thread const float4 (&atten_params)[2])
{
    float atten = 1.0;
    switch (atten_curve_type) {
        case 1: {
            float begin_atten = atten_params[0].x;
            float end_atten   = atten_params[0].y;
            float param       = dist;
            float param_1     = begin_atten;
            float param_2     = end_atten;
            float param_3     = param;
            float param_4     = param_1;
            float param_5     = param_2;
            atten             = linear_interpolate(param_3, param_4, param_5);
            break;
        }
        case 2: {
            float begin_atten_1 = atten_params[0].x;
            float end_atten_1   = atten_params[0].y;
            float param_3_1     = dist;
            float param_4_1     = begin_atten_1;
            float param_5_1     = end_atten_1;
            float param_6       = param_3_1;
            float param_7       = param_4_1;
            float param_8       = param_5_1;
            float tmp           = linear_interpolate(param_6, param_7, param_8);
            atten               = (3.0 * pow(tmp, 2.0)) - (2.0 * pow(tmp, 3.0));
            break;
        }
        case 3: {
            float scale  = atten_params[0].x;
            float offset = atten_params[0].y;
            float kl     = atten_params[0].z;
            float kc     = atten_params[0].w;
            atten        = clamp((scale / ((kl * dist) + (kc * scale))) + offset, 0.0, 1.0);
            break;
        }
        case 4: {
            float scale_1  = atten_params[0].x;
            float offset_1 = atten_params[0].y;
            float kq       = atten_params[0].z;
            float kl_1     = atten_params[0].w;
            float kc_1     = atten_params[1].x;
            atten          = clamp(pow(scale_1, 2.0) / ((((kq * pow(dist, 2.0)) + ((kl_1 * dist) * scale_1)) + (kc_1 * pow(scale_1, 2.0))) + offset_1), 0.0, 1.0);
            break;
        }
        case 0: {
            break;
        }
        default: {
            break;
        }
    }
    return atten;
}

vertex basic_vert_main_out basic_vert_main(basic_vert_main_in in [[stage_in]], constant PerFrameConstants& v_43 [[buffer(10)]], constant PerBatchConstants& v_24 [[buffer(11)]])
{
    basic_vert_main_out out = {};

    float4x4 transM = v_43.worldMatrix * v_24.objectLocalMatrix;
    out.v_world     = transM * float4(in.inputPosition, 1.0f);
    out.v           = v_43.viewMatrix * out.v_world;
    out.gl_Position = v_43.projectionMatrix * out.v;

    out.normal_world = normalize(transM * float4(in.inputNormal, 0.0f));
    out.normal       = normalize(v_43.viewMatrix * out.normal_world);
    out.uv.x         = in.inputUV.x;
    out.uv.y         = 1.0 - in.inputUV.y;
    return out;
}

fragment float4 basic_frag_main(basic_vert_main_out in [[stage_in]], texture2d<float> diffuseMap [[texture(0)]], sampler samp0 [[sampler(0)]], constant PerFrameConstants& v_43 [[buffer(10)]], constant PerBatchConstants& v_24 [[buffer(11)]])
{
    float3 N         = in.normal.xyz;
    float3 L         = (v_43.viewMatrix * v_43.worldMatrix * v_43.lightPosition).xyz - in.v.xyz;
    float3 light_dir = normalize((v_43.viewMatrix * v_43.worldMatrix * v_43.lightDirection).xyz);

    float lightToSurfDist  = length(L);
    L                      = normalize(L);
    float lightToSurfAngle = acos(dot(L, -light_dir));
    float cosTheta         = clamp(dot(N, L), 0.0, 1.0);

    int    param_1 = v_43.lightAngleAttenCurveType;
    float4 param_2[2];
    spvArrayCopyConstant(param_2, v_43.lightAngleAttenCurveParams);
    // angle attenuation
    float atten = apply_atten_curve(lightToSurfAngle, param_1, param_2);

    int    param_4 = v_43.lightDistAttenCurveType;
    float4 param_5[2];
    spvArrayCopyConstant(param_5, v_43.lightDistAttenCurveParams);
    // distance attenuation
    atten *= apply_atten_curve(lightToSurfDist, param_4, param_5);

    float3 R = normalize((N * (2.0 * dot(L, N))) - L);
    float3 V = normalize(-in.v.xyz);

    if (v_24.diffuseColor.r < 0) {
        float3 linearColor = diffuseMap.sample(samp0, in.uv).xyz * cosTheta;
        linearColor        = linearColor + v_24.specularColor.xyz * pow(clamp(dot(R, V), 0.0f, 1.0f), v_24.specularPower);
        float3 admit_light = v_43.lightColor.xyz * (v_43.lightIntensity * atten);

        return float4(v_43.ambientColor.xyz + linearColor * admit_light, 1.0f);
    } else {
        float3 linearColor = v_24.diffuseColor.xyz * cosTheta + v_24.specularColor.xyz * pow(clamp(dot(R, V), 0.0f, 1.0f), v_24.specularPower);
        float3 admit_light = v_43.lightColor.xyz * (v_43.lightIntensity * atten);
        return float4(v_43.ambientColor.xyz + linearColor * admit_light, 1.0f);
    }
}
