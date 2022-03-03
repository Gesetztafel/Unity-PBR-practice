#ifndef GESETZ_COMMON_SHADING_INCLUDED
#define GESETZ_COMMON_SHADING_INCLUDED

struct ShadingParameters
{
	float3x3 tangentToWorld;//TBN matrix

	float3 positionWS;
	float3 viewDir;
	float3 geometricNormalWS;
	float3 reflected;
	float NdotV;
	float3 normalWS;
#if defined(CLEAR_COAT)
    float3  clearCoatNormalWS;
#endif
#if defined(BENT_NORMAL)
    float3  bentNormalWS;
#endif

#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor;
#endif
//No LightMap
// #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
// 	float2 lightmapUV;
// #endif
//
// #if defined(DYNAMICLIGHTMAP_ON)
// 	float2 dynamicLightmapUV;
// #endif
};

#endif