#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

struct Light {
    float4x4 lightVP;                     // 64 bytes
    float4 lightPosition;                 // 16 bytes
    float4 lightColor;                    // 16 bytes
    float4 lightDirection;                // 16 bytes
    float lightDistAttenCurveParams[8];   // 32 bytes
    float lightAngleAttenCurveParams[8];  // 32 bytes
    float2 lightSize;                     // 8 bytes
    int lightDistAttenCurveType;          // 4 bytes
    int lightAngleAttenCurveType;         // 4 bytes
    float lightIntensity;                 // 4 bytes
    int lightType;                        // 4 bytes
    int lightCastShadow;                  // 4 bytes
    int lightShadowMapIndex;              // 4 bytes
    // Above is 208 bytes

    // Fill bytes to align to 256 bytes (Metal required)
    float padding[12];  // 48 bytes
};

struct LightInfo {
    Light lights[100];
};

struct PerFrameConstants {
    float4x4 worldMatrix;       // 64 bytes
    float4x4 viewMatrix;        // 64 bytes
    float4x4 projectionMatrix;  // 64 bytes
    float4 ambientColor;        // 16 bytes
    int numLights;              // 4 bytes
};

struct PerBatchConstants {
    float4x4 objectLocalMatrix;  // 64 bytes
    float4 diffuseColor;         // 16 bytes
    float4 specularColor;        // 16 bytes
    float specularPower;         // 4 bytes
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
void spvArrayCopy(thread T (&dst)[N], thread const T (&src)[N]) {
    for (uint i = 0; i < N; dst[i] = src[i], i++)
        ;
}

// An overload for constant arrays.
template <typename T, uint N>
void spvArrayCopyConstant(thread T (&dst)[N], constant T (&src)[N]) {
    for (uint i = 0; i < N; dst[i] = src[i], i++)
        ;
}

float linear_interpolate(thread const float &t, thread const float &begin, thread const float &end) {
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

float apply_atten_curve(thread const float &dist, thread const int &atten_curve_type, thread const float (&atten_params)[8]) {
    float atten = 1.0;
    switch (atten_curve_type) {
        case 1: {
            float begin_atten = atten_params[0];
            float end_atten   = atten_params[1];
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
            float begin_atten_1 = atten_params[0];
            float end_atten_1   = atten_params[1];
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
            float scale  = atten_params[0];
            float offset = atten_params[1];
            float kl     = atten_params[2];
            float kc     = atten_params[3];
            atten        = clamp((scale / ((kl * dist) + (kc * scale))) + offset, 0.0, 1.0);
            break;
        }
        case 4: {
            float scale_1  = atten_params[0];
            float offset_1 = atten_params[1];
            float kq       = atten_params[2];
            float kl_1     = atten_params[3];
            float kc_1     = atten_params[4];
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

float shadow_test(constant Light &light, float4 v_world, float cosTheta, thread depth2d_array<float> shadowMap) {
    // shadow test
    float visibility = 1.0;

    if (light.lightShadowMapIndex > -1) {
        float4 v_light_space = light.lightVP * v_world;
        v_light_space        = v_light_space / v_light_space.w;
        v_light_space.xy     = 0.5 * (v_light_space.xy + float2(1.0, 1.0));
        // The shadow map we drew already flipped
        // v_light_space.y      = 1.0 - v_light_space.y;

        constexpr sampler shadowSampler(coord::normalized,
                                        filter::linear,
                                        mip_filter::none,
                                        address::clamp_to_edge,
                                        compare_func::less);

        const float2 poissonDisk[4] = {
            float2(-0.94201624, -0.39906216),
            float2(0.94558609, -0.76890725),
            float2(-0.094184101, -0.92938870),
            float2(0.34495938, 0.29387760)};

        float bias = 5e-6 * tan(acos(cosTheta));  // cosTheta is dot( n,l ), clamped between 0 and 1
        bias       = clamp(bias, 0.0, 0.01);
        for (int i = 0; i < 4; i++) {
            float shadow_sample = shadowMap.sample_compare(shadowSampler, v_light_space.xy + poissonDisk[i] / 700.0, light.lightShadowMapIndex, v_light_space.z - bias);
            if (shadow_sample < 0.5) {
                // we are in the shadow
                visibility -= 0.2;
            }
        }
    }

    return visibility;
}

float shadow_test(constant Light &light, float4 v_world, float cosTheta, thread depthcube_array<float> shadowMap) {
    // shadow test
    float visibility = 1.0;

    if (light.lightShadowMapIndex > -1) {
        float3 v_light_space = (v_world - light.lightPosition).xyz;
        normalize(v_light_space);

        constexpr sampler shadowSampler(coord::normalized,
                                        filter::linear,
                                        mip_filter::none,
                                        address::clamp_to_edge,
                                        compare_func::less);

        float bias = 5e-6 * tan(acos(cosTheta));  // cosTheta is dot( n,l ), clamped between 0 and 1
        bias       = clamp(bias, 0.0, 0.01);

        float shadow_sample = shadowMap.sample_compare(shadowSampler, v_light_space, light.lightShadowMapIndex, (1.0 - bias));
        if (shadow_sample < 0.5) {
            // we are in the shadow
            visibility -= 0.2;
        }
    }

    return visibility;
}

bool isAbovePlane(thread const float3 &_point, thread const float3 &center_of_plane, thread const float3 &normal_of_plane) {
    return dot(_point - center_of_plane, normal_of_plane) > 0.0;
}

float3 linePlaneIntersect(thread const float3 &line_start, thread const float3 &line_dir, thread const float3 &center_of_plane, thread const float3 &normal_of_plane) {
    return line_start + (line_dir * (dot(center_of_plane - line_start, normal_of_plane) / dot(line_dir, normal_of_plane)));
}

float3 projectOnPlane(thread const float3 &_point, thread const float3 &center_of_plane, thread const float3 &normal_of_plane) {
    return _point - (normal_of_plane * dot(_point - center_of_plane, normal_of_plane));
}

float3 apply_areaLight(constant Light &light, thread const basic_vert_main_out &in, constant PerFrameConstants &pfc, constant PerBatchConstants &pbc, thread texture2d<float> diffuseMap, thread sampler samp0) {
    float3 linearColor = float3(0.0);

    float3 N       = normalize(in.normal.xyz);
    float3 right   = normalize((pfc.viewMatrix * float4(1.0, 0.0, 0.0, 0.0)).xyz);
    float3 pnormal = normalize((pfc.viewMatrix * light.lightDirection).xyz);
    float3 ppos    = (pfc.viewMatrix * light.lightPosition).xyz;
    float3 up      = normalize(cross(pnormal, right));
    right          = normalize(cross(up, pnormal));

    float width       = light.lightSize.x;
    float height      = light.lightSize.y;
    float3 param      = in.v.xyz;
    float3 param_1    = ppos;
    float3 param_2    = pnormal;
    float3 projection = projectOnPlane(param, param_1, param_2);

    float3 dir                = projection - ppos;
    float2 diagonal           = float2(dot(dir, right), dot(dir, up));
    float2 nearest2D          = float2(clamp(diagonal.x, -width, width), clamp(diagonal.y, -height, height));
    float3 nearestPointInside = (ppos + (right * nearest2D.x)) + (up * nearest2D.y);
    float3 L                  = nearestPointInside - in.v.xyz;
    float lightToSurfDist     = length(L);
    L                         = normalize(L);

    float param_3 = lightToSurfDist;
    int param_4   = light.lightDistAttenCurveType;
    float param_5[8];
    spvArrayCopyConstant(param_5, light.lightDistAttenCurveParams);

    float atten    = apply_atten_curve(param_3, param_4, param_5);
    float pnDotL   = dot(pnormal, -L);
    float nDotL    = dot(N, L);
    float3 param_6 = in.v.xyz;
    float3 param_7 = ppos;
    float3 param_8 = pnormal;
    if ((nDotL > 0.0) && isAbovePlane(param_6, param_7, param_8)) {
        float3 V  = normalize(-in.v.xyz);
        float3 R  = normalize((N * (2.0 * dot(V, N))) - V);
        float3 R2 = normalize((N * (2.0 * dot(L, N))) - L);

        float3 param_9  = in.v.xyz;
        float3 param_10 = R;
        float3 param_11 = ppos;
        float3 param_12 = pnormal;
        float3 E        = linePlaneIntersect(param_9, param_10, param_11, param_12);

        float specAngle      = clamp(dot(-R, pnormal), 0.0, 1.0);
        float3 dirSpec       = E - ppos;
        float2 dirSpec2D     = float2(dot(dirSpec, right), dot(dirSpec, up));
        float2 nearestSpec2D = float2(clamp(dirSpec2D.x, -width, width), clamp(dirSpec2D.y, -height, height));
        float specFactor     = 1.0 - clamp(length(nearestSpec2D - dirSpec2D), 0.0, 1.0);
        float3 admit_light   = light.lightColor.xyz * (light.lightIntensity * atten);

        if (pbc.diffuseColor.r < 0) {
            linearColor = (diffuseMap.sample(samp0, in.uv).xyz * nDotL) * pnDotL;
            linearColor += (((pbc.specularColor.xyz * pow(clamp(dot(R2, V), 0.0f, 1.0f), pbc.specularPower)) * specFactor) * specAngle);
            linearColor *= admit_light;
        } else {
            linearColor = (pbc.diffuseColor.xyz * nDotL) * pnDotL;
            linearColor += (((pbc.specularColor.xyz * pow(clamp(dot(R2, V), 0.0f, 1.0f), pbc.specularPower)) * specFactor) * specAngle);
            linearColor *= admit_light;
        }
    }

    return linearColor;
}

float3 apply_light(constant Light &light, thread const basic_vert_main_out &in, constant PerFrameConstants &pfc, constant PerBatchConstants &pbc, thread texture2d<float> diffuseMap, thread depth2d_array<float> shadowMap, thread depthcube_array<float> cubeShadowMap, thread depth2d_array<float> globalShadowMap, thread sampler samp0) {
    float3 linearColor = float3(0.0);

    float3 N = in.normal.xyz;
    float3 L;
    float3 light_dir = normalize((pfc.viewMatrix * pfc.worldMatrix * light.lightDirection).xyz);
    if (light.lightPosition.w == 0.0f) {
        L = -light_dir;
    } else {
        L = (pfc.viewMatrix * pfc.worldMatrix * light.lightPosition).xyz - in.v.xyz;
    }

    float lightToSurfDist  = length(L);
    L                      = normalize(L);
    float lightToSurfAngle = acos(dot(L, -light_dir));
    float cosTheta         = clamp(dot(N, L), 0.0, 1.0);

    // shadow test
    float visibility = 1.0;
    switch (light.lightType) {
        case 0: {
            visibility *= shadow_test(light, in.v_world, cosTheta, cubeShadowMap);
            break;
        }
        case 1: {
            visibility *= shadow_test(light, in.v_world, cosTheta, shadowMap);
            break;
        }
        case 2: {
            visibility *= shadow_test(light, in.v_world, cosTheta, shadowMap);
            break;
        }
        case 3: {
            visibility *= shadow_test(light, in.v_world, cosTheta, globalShadowMap);
            break;
        }
    }

    int param_1 = light.lightAngleAttenCurveType;
    float param_2[8];
    spvArrayCopyConstant(param_2, light.lightAngleAttenCurveParams);
    float atten = apply_atten_curve(lightToSurfAngle, param_1, param_2);

    int param_4 = light.lightDistAttenCurveType;
    float param_5[8];
    spvArrayCopyConstant(param_5, light.lightDistAttenCurveParams);
    atten *= apply_atten_curve(lightToSurfDist, param_4, param_5);

    float3 R = normalize((N * (2.0 * dot(L, N))) - L);
    float3 V = normalize(-in.v.xyz);

    if (pbc.diffuseColor.r < 0) {
        linearColor = diffuseMap.sample(samp0, in.uv).xyz * cosTheta;
        linearColor += pbc.specularColor.xyz * pow(clamp(dot(R, V), 0.0f, 1.0f), pbc.specularPower);
        linearColor *= light.lightColor.xyz * (light.lightIntensity * atten);
    } else {
        linearColor = pbc.diffuseColor.xyz * cosTheta + pbc.specularColor.xyz * pow(clamp(dot(R, V), 0.0f, 1.0f), pbc.specularPower);
        linearColor *= light.lightColor.xyz * (light.lightIntensity * atten);
    }

    return linearColor * visibility;
}

vertex basic_vert_main_out basic_vert_main(basic_vert_main_in in [[stage_in]], constant PerFrameConstants &pfc [[buffer(10)]], constant PerBatchConstants &pbc [[buffer(11)]]) {
    basic_vert_main_out out = {};

    float4x4 transM = pfc.worldMatrix * pbc.objectLocalMatrix;
    out.v_world     = transM * float4(in.inputPosition, 1.0f);
    out.v           = pfc.viewMatrix * out.v_world;
    out.gl_Position = pfc.projectionMatrix * out.v;

    out.normal_world = normalize(transM * float4(in.inputNormal, 0.0f));
    out.normal       = normalize(pfc.viewMatrix * out.normal_world);
    out.uv.x         = in.inputUV.x;
    out.uv.y         = 1.0 - in.inputUV.y;
    return out;
}

fragment float4 basic_frag_main(basic_vert_main_out in [[stage_in]],
                                constant PerFrameConstants &pfc [[buffer(10)]],
                                constant PerBatchConstants &pbc [[buffer(11)]],
                                constant LightInfo &pfc_light [[buffer(12)]],
                                texture2d<float> diffuseMap [[texture(0)]],
                                depth2d_array<float> shadowMap [[texture(1)]],
                                depthcube_array<float> cubeShadowMap [[texture(2)]],
                                depth2d_array<float> globalShadowMap [[texture(3)]],
                                sampler samp0 [[sampler(0)]]) {
    float3 linearColor = float3(0.0);

    for (int i = 0; i < pfc.numLights; i++) {
        if (pfc_light.lights[i].lightType == 3) {
            linearColor += apply_areaLight(pfc_light.lights[i], in, pfc, pbc, diffuseMap, samp0);
        } else {
            linearColor += apply_light(pfc_light.lights[i], in, pfc, pbc, diffuseMap, shadowMap, cubeShadowMap, globalShadowMap, samp0);
        }
    }

    // gama correction
    linearColor = clamp(pow(pfc.ambientColor.xyz + linearColor, float3(1.0f / 2.2f)), 0.0f, 1.0f);

    return float4(linearColor, 1.0f);
}
