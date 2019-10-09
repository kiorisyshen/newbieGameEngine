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

struct PerBatchConstants {
    float4x4 objectLocalMatrix;
};

struct PerFrameConstants {
    float4x4 worldMatrix;  // 64 bytes
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 camPos;
    int numLights;
};

struct pbr_frag_main_out {
    float4 outputColor [[color(0)]];
};

struct pbr_vert_main_out {
    float4 normal [[user(locn0)]];
    float4 normal_world [[user(locn1)]];
    float4 v [[user(locn2)]];
    float4 v_world [[user(locn3)]];
    float2 uv [[user(locn4)]];
    float4 gl_Position [[position]];
};

struct pbr_vert_main_in {
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

float3 inverse_gamma_correction(thread const float3 &color) {
    return pow(max(color, float3(0.0)), float3(2.1));
}

float shadow_test(thread const float4 &p, thread const Light &light, thread const float &cosTheta, thread depthcube_array<float> cubeShadowMap, thread sampler samp0, thread depth2d_array<float> shadowMap, thread depth2d_array<float> globalShadowMap) {
    float4 v_light_space = light.lightVP * p;
    v_light_space /= float4(v_light_space.w);
    float visibility = 1.0;
    if (light.lightCastShadow != 0u) {
        float bias0 = 0.0005000000237487256526947021484375 * tan(acos(cosTheta));
        bias0       = clamp(bias0, 0.0, 0.00999999977648258209228515625);
        float near_occ;
        int i;
        switch (light.lightType) {
            case 0: {
                float3 L = p.xyz - light.lightPosition.xyz;
                near_occ = cubeShadowMap.sample(samp0, float4(L, float(light.lightShadowMapIndex)).xyz, uint(round(float4(L, float(light.lightShadowMapIndex)).w)));
                if ((length(L) - (near_occ * 10.0)) > bias0) {
                    visibility -= 0.87999999523162841796875;
                }
                break;
            }
            case 1: {
                v_light_space = float4x4(float4(0.5, 0.0, 0.0, 0.0), float4(0.0, 0.5, 0.0, 0.0), float4(0.0, 0.0, 0.5, 0.0), float4(0.5, 0.5, 0.5, 1.0)) * v_light_space;
                i             = 0;
                for (; i < 4; i++) {
                    float4x2 indexable = float4x2(float2(-0.94201624393463134765625, -0.39906215667724609375), float2(0.94558608531951904296875, -0.768907248973846435546875), float2(-0.094184100627899169921875, -0.929388701915740966796875), float2(0.34495937824249267578125, 0.29387760162353515625));
                    near_occ           = shadowMap.sample(samp0, float3(v_light_space.xy + (indexable[i] / float2(700.0)), float(light.lightShadowMapIndex)).xy, uint(round(float3(v_light_space.xy + (indexable[i] / float2(700.0)), float(light.lightShadowMapIndex)).z)));
                    if ((v_light_space.z - near_occ) > bias0) {
                        visibility -= 0.2199999988079071044921875;
                    }
                }
                break;
            }
            case 2: {
                v_light_space = float4x4(float4(0.5, 0.0, 0.0, 0.0), float4(0.0, 0.5, 0.0, 0.0), float4(0.0, 0.0, 0.5, 0.0), float4(0.5, 0.5, 0.5, 1.0)) * v_light_space;
                i             = 0;
                for (; i < 4; i++) {
                    float4x2 indexable_1 = float4x2(float2(-0.94201624393463134765625, -0.39906215667724609375), float2(0.94558608531951904296875, -0.768907248973846435546875), float2(-0.094184100627899169921875, -0.929388701915740966796875), float2(0.34495937824249267578125, 0.29387760162353515625));
                    near_occ             = globalShadowMap.sample(samp0, float3(v_light_space.xy + (indexable_1[i] / float2(700.0)), float(light.lightShadowMapIndex)).xy, uint(round(float3(v_light_space.xy + (indexable_1[i] / float2(700.0)), float(light.lightShadowMapIndex)).z)));
                    if ((v_light_space.z - near_occ) > bias0) {
                        visibility -= 0.2199999988079071044921875;
                    }
                }
                break;
            }
            case 3: {
                v_light_space = float4x4(float4(0.5, 0.0, 0.0, 0.0), float4(0.0, 0.5, 0.0, 0.0), float4(0.0, 0.0, 0.5, 0.0), float4(0.5, 0.5, 0.5, 1.0)) * v_light_space;
                i             = 0;
                for (; i < 4; i++) {
                    float4x2 indexable_2 = float4x2(float2(-0.94201624393463134765625, -0.39906215667724609375), float2(0.94558608531951904296875, -0.768907248973846435546875), float2(-0.094184100627899169921875, -0.929388701915740966796875), float2(0.34495937824249267578125, 0.29387760162353515625));
                    near_occ             = shadowMap.sample(samp0, float3(v_light_space.xy + (indexable_2[i] / float2(700.0)), float(light.lightShadowMapIndex)).xy, uint(round(float3(v_light_space.xy + (indexable_2[i] / float2(700.0)), float(light.lightShadowMapIndex)).z)));
                    if ((v_light_space.z - near_occ) > bias0) {
                        visibility -= 0.2199999988079071044921875;
                    }
                }
                break;
            }
        }
    }
    return visibility;
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

float DistributionGGX(thread const float3 &N, thread const float3 &H, thread const float &roughness) {
    float a      = roughness * roughness;
    float a2     = a * a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    float num    = a2;
    float denom  = (NdotH2 * (a2 - 1.0)) + 1.0;
    denom        = (3.1415927410125732421875 * denom) * denom;
    return num / denom;
}

float GeometrySchlickGGXDirect(thread const float &NdotV, thread const float &roughness) {
    float r     = roughness + 1.0;
    float k     = (r * r) / 8.0;
    float num   = NdotV;
    float denom = (NdotV * (1.0 - k)) + k;
    return num / denom;
}

float GeometrySmithDirect(thread const float3 &N, thread const float3 &V, thread const float3 &L, thread const float &roughness) {
    float NdotV   = max(dot(N, V), 0.0);
    float NdotL   = max(dot(N, L), 0.0);
    float param   = NdotV;
    float param_1 = roughness;
    float ggx2    = GeometrySchlickGGXDirect(param, param_1);
    float param_2 = NdotL;
    float param_3 = roughness;
    float ggx1    = GeometrySchlickGGXDirect(param_2, param_3);
    return ggx1 * ggx2;
}

float3 fresnelSchlick(thread const float &cosTheta, thread const float3 &F0) {
    return F0 + ((float3(1.0) - F0) * pow(1.0 - cosTheta, 5.0));
}

float3 fresnelSchlickRoughness(thread const float &cosTheta, thread const float3 &F0, thread const float &roughness) {
    return F0 + ((max(float3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0));
}

float3 reinhard_tone_mapping(thread const float3 &color) {
    return color / (color + float3(1.0));
}

float3 gamma_correction(thread const float3 &color) {
    return pow(max(color, float3(0.0)), float3(0.47619047619048));
}

vertex pbr_vert_main_out pbr_vert_main(pbr_vert_main_in in [[stage_in]], constant PerFrameConstants &pfc [[buffer(10)]], constant PerBatchConstants &pbc [[buffer(11)]]) {
    pbr_vert_main_out out = {};

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

fragment float4 pbr_frag_main(pbr_vert_main_out in [[stage_in]],
                              constant PerFrameConstants &pfc [[buffer(10)]],
                              constant LightInfo &pfc_light [[buffer(12)]],
                              texture2d<float> diffuseMap [[texture(0)]],
                              texture2d<float> normalMap [[texture(1)]],
                              texture2d<float> metallicMap [[texture(2)]],
                              texture2d<float> roughnessMap [[texture(3)]],
                              texture2d<float> aoMap [[texture(4)]],
                              texture2d<float> brdfLUT [[texture(6)]],
                              depth2d_array<float> shadowMap [[texture(7)]],
                              depth2d_array<float> globalShadowMap [[texture(8)]],
                              depthcube_array<float> cubeShadowMap [[texture(9)]],
                              texturecube_array<float> skybox [[texture(10)]],
                              sampler samp0 [[sampler(0)]]) {
    // pbr_frag_main_out out = {};
    float3 outColor = float3(0.0f);

    float3 param  = diffuseMap.sample(samp0, in.uv).xyz;
    float3 albedo = inverse_gamma_correction(param);
    float meta    = metallicMap.sample(samp0, in.uv).x;
    float rough   = roughnessMap.sample(samp0, in.uv).x;
    float3 F0     = float3(0.04);
    F0            = mix(F0, albedo, meta);

    float3 N    = normalize(in.normal_world.xyz);
    float3 V    = normalize(pfc.camPos.xyz - in.v_world.xyz);
    float3 R    = reflect(-V, N);
    float NdotV = max(dot(N, V), 0.0);

    // reflectance equation
    float3 Lo = float3(0.0);
    for (int i = 0; i < pfc.numLights; i++) {
        Light light = pfc_light.lights[i];

        float3 L    = normalize(light.lightPosition.xyz - in.v_world.xyz);
        float3 H    = normalize(V + L);
        float NdotL = max(dot(N, L), 0.0);

        float visibility = shadow_test(in.v_world, light, NdotL, cubeShadowMap, samp0, shadowMap, globalShadowMap);

        float lightToSurfAngle = acos(dot(-L, light.lightDirection.xyz));
        float param_3[8];
        spvArrayCopy(param_3, light.lightAngleAttenCurveParams);
        float atten = apply_atten_curve(lightToSurfAngle, light.lightAngleAttenCurveType, param_3);

        float lightToSurfDist = length(L);
        float param_6[8];
        spvArrayCopy(param_6, light.lightDistAttenCurveParams);
        atten *= apply_atten_curve(lightToSurfDist, light.lightDistAttenCurveType, param_6);

        float3 radiance = light.lightColor.xyz * (light.lightIntensity * atten);

        float NDF = DistributionGGX(N, H, rough);
        float G   = GeometrySmithDirect(H, V, L, rough);
        float3 F  = fresnelSchlick(max(dot(H, V), 0.0), F0);

        float3 kS = F;
        float3 kD = float3(1.0) - kS;
        kD *= (1.0 - meta);

        float3 numerator  = F * (NDF * G);
        float denominator = (4.0 * NdotV) * NdotL;
        float3 specular   = numerator / float3(max(denominator, 0.001));

        Lo += ((kD * albedo) / 3.1415927410125732421875 + specular) * radiance * NdotL * visibility;
    }

    float3 ambient = float3(0.0);
    {
        float ambientOcc = aoMap.sample(samp0, in.uv).x;
        if (ambientOcc <= 0.000000001) {
            ambientOcc = 1.0;
        }

        float3 F  = fresnelSchlickRoughness(NdotV, F0, rough);
        float3 kS = F;
        float3 kD = float3(1.0) - kS;
        kD *= (1.0 - meta);

        float3 irradiance = skybox.sample(samp0, N, 0, level(1.0)).xyz;
        float3 diffuse    = irradiance * albedo;

        float3 prefilteredColor = skybox.sample(samp0, R, 1, level(rough * 9.0)).xyz;
        float2 envBRDF          = brdfLUT.sample(samp0, float2(NdotV, rough)).xy;
        float3 specular         = prefilteredColor * (F * envBRDF.x + float3(envBRDF.y));

        ambient = (kD * diffuse + specular) * ambientOcc;
    }

    outColor = Lo + ambient;
    outColor = reinhard_tone_mapping(outColor);
    outColor = gamma_correction(outColor);

    return float4(outColor, 1.0);
}
