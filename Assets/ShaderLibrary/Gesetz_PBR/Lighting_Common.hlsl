#ifndef GESETZ_LIGHTING_COMMON_INCLUDED
#define GESETZ_LIGHTING_COMMON_INCLUDED

#include "UnityLightingCommon.cginc"
#include "Materials_Input.hlsl"
// float4 _LightColor0;
// float4 _SpecColor;
//
// struct UnityLight
// {
//     half3 color;
//     half3 dir;
//     half  ndotl; // Deprecated: Ndotl is now calculated on the fly and is no longer stored. Do not used it.
// };
// struct UnityIndirect
// {
//     half3 diffuse;
//     half3 specular;
// };
//
// struct UnityGI
// {
//     UnityLight light;
//     UnityIndirect indirect;
// };
//
// struct UnityGIInput
// {
//     UnityLight light; // pixel light, sent from the engine
//
//     float3 worldPos;
//     half3 worldViewDir;
//     half atten;
//     half3 ambient;
//
//     // interpolated lightmap UVs are passed as full float precision data to fragment shaders
//     // so lightmapUV (which is used as a tmp inside of lightmap fragment shaders) should
//     // also be full float precision to avoid data loss before sampling a texture.
//     float4 lightmapUV; // .xy = static lightmap UV, .zw = dynamic lightmap UV
//
//     #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION) || defined(UNITY_ENABLE_REFLECTION_BUFFERS)
//     float4 boxMin[2];
//     #endif
//     #ifdef UNITY_SPECCUBE_BOX_PROJECTION
//     float4 boxMax[2];
//     float4 probePosition[2];
//     #endif
//     // HDR cubemap properties, use to decompress HDR texture
//     float4 probeHDR[2];
// };

// struct Light {
//     float4 colorIntensity;  // rgb, pre-exposed intensity
//     float3 l;
//     float attenuation;
//     float NoL;
//     float3 worldPosition;
//     bool castsShadows;
//     bool contactShadows;
//     uint shadowIndex;
//     uint shadowLayer;
//     uint channels;
// };

struct PixelParams
{
	float3 diffColor;
	float perceptualRoughness;
	float perceptualRoughnessUnclamped;
	float3 F0;
	float roughness;

	float3 DFG;
	float3 energyCompensation;
	
#if defined(CLEAR_COAT)
    float clearCoat;
    float clearCoatPerceptualRoughness;
    float clearCoatRoughness;
#endif
	
// #if defined(SHEEN_COLOR)
//     float3  sheenColor;
// #if !defined(SHADING_MODE_CLOTH)
//     float sheenRoughness;
//     float sheenPerceptualRoughness;
//     float sheenScaling;
//     float sheenDFG;
// #endif
// #endif
	
#if defined(ANISOTROPY)
    float3  anisotropicT;
    float3  anisotropicB;
    float anisotropy;
#endif
	
// #if defined(SHADING_MODE_SUBSURFACE)||defined(REFRACTION)
//     float thickness;
// #endif
// #if defined(SHADING_MODEL_SUBSURFACE)
//     float3  subsurfaceColor;
//     float subsurfacePower;
// #endif

// #if defined(SHADING_MODEL_CLOTH) && defined(SUBSURFACE_COLOR)
//     float3  subsurfaceColor;
// #endif

// #if defined(REFRACTION)
//     float etaRI;
//     float etaIR;
//     float transmission;
//     float uThickness;
//     float3  absorption;
// #endif
};

// [Chan 18] "Material Advances in Call of Duty: WWII"
float computeMicroShadowing(float NdotL, float visibility) {
    float aperture = rsqrt(1.0 - visibility);
    float microShadow = saturate(NdotL * aperture);
    return microShadow * microShadow;
}


float3 getReflectedVector(const PixelParams pixel, const float3 v, const float3 n) {
#if defined(ANISOTROPY)
    float3  anisotropyDirection = pixel.anisotropy >= 0.0 ? pixel.anisotropicB : pixel.anisotropicT;
    float3  anisotropicTangent  = cross(anisotropyDirection, v);
    float3  anisotropicNormal   = cross(anisotropicTangent, anisotropyDirection);
    float bendFactor          = abs(pixel.anisotropy) * saturate(5.0 * pixel.perceptualRoughness);
    float3  bentNormal          = normalize(mix(n, anisotropicNormal, bendFactor));

    float3 r = reflect(-v, bentNormal);
#else
    float3 r = reflect(-v, n);
#endif
    return r;
}

// void getAnisotropyPixelParams(const ExtendedMaterialInputs material,
// 							inout PixelParams pixel) {
// #if defined(ANISOTROPY)
//     float3 direction = anisotropyDirection;
//     pixel.anisotropy = anisotropy;
//     
//     pixel.anisotropicT = normalize(shading_tangentToWorld * direction);	
//     pixel.anisotropicB = normalize(cross(getWorldGeometricNormalVector(), pixel.anisotropicT));
// #endif
// }

#endif