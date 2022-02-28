#ifndef GESETZ_AMBIENT_OCCLUSION_INCLUDED
#define GESETZ_AMBIENT_OCCLUSION_INCLUDED

#include "Lighting_Common.hlsl"
//Move to Shading_Config.hlsl

// Diffuse BRDFs
#define SPECULAR_AO_OFF             0
#define SPECULAR_AO_SIMPLE          1
#define SPECULAR_AO_BENT_NORMALS    2

float Unpack(float2 depth)
{
	return (depth.x*(256.0/257.0)+depth.y*(1.0/257.0));
}

// float evaluateSSAO(){
//...
// }

//[Lagarde 14] "Moving Frostbite to PBR"
float Specular_Lagarde(float NdotV,float visibility,float roughness)
{
	return saturate(pow(NdotV+visibility,exp2(-16.0*roughness-1.0))-1.0+visibility);
}

// [Oat&Sander 07]
// float sphericalCapsIntersection(float cosCap1, float cosCap2, float cosDistance)
// {
// 	...
// }

// [Jimenez 16] "Practical Realtime Strategies for Accurate Indirect Occlusion"
// float SpecularAO_Cones(vec3 bentNormal, float visibility, float roughness)
// {
// ...
// }

float SpecualrAO(float NdotV,float visibility,float roughness/*, const in SSAOInterpolationCache cache*/)
{
	float specularAO = 1.0;
// #if defined(BLEND_MODE_OPAQUE) || defined(BLEND_MODE_MASKED)
	
// #if SPECULAR_AMBIENT_OCCLUSION == SPECULAR_AO_SIMPLE
    // TODO: Should we even bother computing this when screen space bent normals are enabled?
    specularAO = Specular_Lagarde(NdotV, visibility, roughness);
// #elif SPECULAR_AMBIENT_OCCLUSION == SPECULAR_AO_BENT_NORMALS
// #if defined(BENT_NORMAL)
//         specularAO = SpecularAO_Cones(shading_bentNormal, visibility, roughness);
// #else
//         specularAO = SpecularAO_Cones(shading_normal, visibility, roughness);
// #endif
// #endif

// #endif

// ...	


	return specularAO;
	
}


#if defined MULTI_BOUNCE_AMBIENT_OCCLUSION
// [Jimenez 16] "Practical Realtime Strategies for Accurate Indirect Occlusion"
float3 GTAOMultiBounce(float visibility,const float3 albedo)
{
	float3 a=2.0404*albedo-0.3324;
	float3 b=-4.7951*albedo+0.6417;
	float3 c=2.7552*albedo+0.6903;

	return max(float3(visibility,visibility,visibility),((visibility*a+b)*visibility+c)*visibility);
}
#endif

void multiBounceAO(float visibility, const float3 albedo, inout float3 color) {
#if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1
    color *= gtaoMultiBounce(visibility, albedo);
#endif
}

void multiBounceSpecularAO(float visibility, const float3 albedo, inout float3 color) {
#if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1 && SPECULAR_AMBIENT_OCCLUSION != SPECULAR_AO_OFF
    color *= gtaoMultiBounce(visibility, albedo);
#endif
}

float singleBounceAO(float visibility)
{
#if defined MULTI_BOUNCE_AMBIENT_OCCLUSION
	return 1.0;
#else
	return visibility;
#endif
}
#endif