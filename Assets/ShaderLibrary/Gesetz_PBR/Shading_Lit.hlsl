#ifndef GESETZ_SHADING_LIT_INCLUDED
#define GESETZ_SHADING_LIT_INCLUDED

#include "Lighting_Common.hlsl"
#include "Shading_Config.hlsl"
#include "Common_Material.hlsl"
#include "Shading_Parameters.hlsl"

//Lighting
// float computeDiffuseAlpha(float a) {
// #if defined(BLEND_MODE_TRANSPARENT) || defined(BLEND_MODE_FADE) || defined(BLEND_MODE_MASKED)
//     return a;
// #else
//     return 1.0;
// #endif
// }
//
// #if defined(BLEND_MODE_MASKED)
// float computeMaskedAlpha(float a) {
//     // Use derivatives to smooth alpha tested edges
//     return (a - getMaskThreshold()) / max(fwidth(a), 1e-3) + 0.5;
// }
// #endif
//
// void applyAlphaMask(inout float4 baseColor) {
// #if defined(BLEND_MODE_MASKED)
//     baseColor.a = computeMaskedAlpha(baseColor.a);
//     if (baseColor.a <= 0.0) {
//         discard;
//     }
// #endif
// }

float _specularAntiAliasingVariance;//0.15
float _specularAntiAliasingThreshold;//0.2

#if defined(GEOMETRIC_SPECULAR_AA)
// [Kaplanyan 16] "Stable specular highlights"
// [Tokuyoshi 17] "Error Reduction and Simplification for Shading Anti-Aliasing"
// [Tokuyoshi&Kaplanyan 19] "Improved Geometric Specular Antialiasing"
float normalFiltering(float perceptualRoughness, const float3 worldNormal)
{
	float3 du=ddx(worldNormal);
	float3 dv=ddy(worldNormal);
	
	float variance = _specularAntiAliasingVariance
				* (dot(du, du) + dot(dv, dv));

    float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
    float kernelRoughness = min(2.0 * variance, 
			_specularAntiAliasingThreshold);
    float squareRoughness = saturate(roughness * roughness + kernelRoughness);

    return RoughnessToPerceptualRoughness(sqrt(squareRoughness));
}
#endif

// void getCommonPixelParams(const MaterialInputs material,out PixelParams pixel)
// {
// 	//getCommonPixelParams
// 	float4 baseColor=material.baseColor;
//
//     pixel.diffColor = computeDiffuseColor(baseColor, material.metallic);
//     float reflectance = computeDielectricF0(material.reflectance);
//
//     pixel.F0 = computeF0(baseColor, material.metallic, reflectance);
// 	
// #if defined(SUBSURFACE_COLOR)
//     pixel.subsurfaceColor = material.subsurfaceColor;
// #endif
//
// #if !defined(SHADING_MODEL_SUBSURFACE) && (!defined(MATERIAL_HAS_REFLECTANCE) && defined(MATERIAL_HAS_IOR))
//     float reflectance = iorToF0(max(1.0, material.ior), 1.0);
// #else
//     // Assumes an interface from air to an IOR of 1.5 for dielectrics
//     float reflectance = computeDielectricF0(material.reflectance);
// #endif
//     pixel.f0 = computeF0(baseColor, material.metallic, reflectance);
// #else
//     pixel.diffuseColor = baseColor.rgb;
//     pixel.f0 = material.sheenColor;
// #if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
//     pixel.subsurfaceColor = material.subsurfaceColor;
// #endif
// #endif
// #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
// #if defined(MATERIAL_HAS_REFRACTION)
//     // Air's Index of refraction is 1.000277 at STP but everybody uses 1.0
//     const float airIor = 1.0;
// #if !defined(MATERIAL_HAS_IOR)
//     // [common case] ior is not set in the material, deduce it from F0
//     float materialor = f0ToIor(pixel.f0.g);
// #else
//     // if ior is set in the material, use it (can lead to unrealistic materials)
//     float materialor = max(1.0, material.ior);
// #endif
//     pixel.etaIR = airIor / materialor;  // air -> material
//     pixel.etaRI = materialor / airIor;  // material -> air
// #if defined(MATERIAL_HAS_TRANSMISSION)
//     pixel.transmission = saturate(material.transmission);
// #else
//     pixel.transmission = 1.0;
// #endif
// #if defined(MATERIAL_HAS_ABSORPTION)
// #if defined(MATERIAL_HAS_THICKNESS) || defined(MATERIAL_HAS_MICRO_THICKNESS)
//     pixel.absorption = max(vec3(0.0), material.absorption);
// #else
//     pixel.absorption = saturate(material.absorption);
// #endif
// #else
//     pixel.absorption = vec3(0.0);
// #endif
// #if defined(MATERIAL_HAS_THICKNESS)
//     pixel.thickness = max(0.0, material.thickness);
// #endif
// #if defined(MATERIAL_HAS_MICRO_THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
//     pixel.uThickness = max(0.0, material.microThickness);
// #else
//     pixel.uThickness = 0.0;
// #endif
// #endif
// #endif
// }
// void getSheenPixelParams(const MaterialInputs material,out PixelParams pixel,const float3 WorldGeometricNormalVector)
// {
// 	#if defined(SHEEN_COLOR) && !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
//     pixel.sheenColor = material.sheenColor;
//
//     float sheenPerceptualRoughness = material.sheenRoughness;
//     sheenPerceptualRoughness = clamp(sheenPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
//
// #if defined(GEOMETRIC_SPECULAR_AA)
//     sheenPerceptualRoughness =
//             normalFiltering(sheenPerceptualRoughness, getWorldGeometricNormalVector());
// #endif
//
//     pixel.sheenPerceptualRoughness = sheenPerceptualRoughness;
//     pixel.sheenRoughness = perceptualRoughnessToRoughness(sheenPerceptualRoughness);
// #endif
// }
// void getClearCoatPixelParams(const MaterialInputs material,out PixelParams pixel,const float3 WorldGeometricNormalVector)
// {
// #if defined(CLEAR_COAT)
//     pixel.clearCoat = material.clearCoat;
//
//     // Clamp the clear coat roughness to avoid divisions by 0
//     float clearCoatPerceptualRoughness = material.clearCoatRoughness;
//     clearCoatPerceptualRoughness =
//             clamp(clearCoatPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
//
// #if defined(GEOMETRIC_SPECULAR_AA)
//     clearCoatPerceptualRoughness =
//             normalFiltering(clearCoatPerceptualRoughness, WorldGeometricNormalVector);
// #endif
//     pixel.clearCoatPerceptualRoughness = clearCoatPerceptualRoughness;
//     pixel.clearCoatRoughness = perceptualRoughnessToRoughness(clearCoatPerceptualRoughness);
//
// // #if defined(CLEAR_COAT_IOR_CHANGE)
// //     // The base layer's f0 is computed assuming an interface from air to an IOR
// //     // of 1.5, but the clear coat layer forms an interface from IOR 1.5 to IOR
// //     // 1.5. We recompute f0 by first computing its IOR, then reconverting to f0
// //     // by using the correct interface
// //     pixel.F0 = lerp(pixel.F0, f0ClearCoatToSurface(pixel.F0), pixel.clearCoat);
// // #endif
// #endif
// }
// void getRoughnessPixelParams(const MaterialInputs material,out PixelParams pixel,const float3 geometricNormalVector)
// {
// 	float perceptualRoughness=material.roughness;
// 	pixel.perceptualRoughnessUnclamped=perceptualRoughness;
//
// #if defined(GEOMETRIC_SPECULAR_AA)
//     perceptualRoughness = normalFiltering(perceptualRoughness, geometricNormalVector);
// #endif
// #if defined(COAT) && defined(CLEAR_COAT_ROUGHNESS)
//     // This is a hack but it will do: the base layer must be at least as rough
//     // as the clear coat layer to take into account possible diffusion by the
//     // top layer
//     float basePerceptualRoughness = max(perceptualRoughness, pixel.clearCoatPerceptualRoughness);
//     perceptualRoughness = mix(perceptualRoughness, basePerceptualRoughness, pixel.clearCoat);
// #endif
//
//     // Clamp the roughness to a minimum value to avoid divisions by 0 during lighting
//     pixel.perceptualRoughness = clamp(perceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
//     // Remaps the roughness to a perceptually linear roughness (roughness^2)
//     pixel.roughness = perceptualRoughnessToRoughness(pixel.perceptualRoughness);
// }
// void getSubsurfacePixelParams(const MaterialInputs material, inout PixelParams pixel) {
// #if defined(SHADING_MODEL_SUBSURFACE)
//     pixel.subsurfacePower = material.subsurfacePower;
//     pixel.subsurfaceColor = material.subsurfaceColor;
//     pixel.thickness = saturate(material.thickness);
// #endif
// }
// void getEnergyCompensationPixelParams(const MaterialInputs material,out PixelParams pixel,float NdotV)
// {
// 	//[Lazarov 13] 
// 	// pixel.DFG=float3(Prefiltered_DFG_Approx(pixel.perceptualRoughness,NdotV),1.0);
// 	//DFG LUT 
// 	pixel.DFG=Prefiltered_DFG(pixel.perceptualRoughness,NdotV);
// 	
// #if !defined(SHADING_MODEL_CLOTH)
//     // Energy compensation for multiple scattering in a microfacet model
//     // See "Multiple-Scattering Microfacet BSDFs with the Smith Model"
//     pixel.energyCompensation = 1.0 + pixel.F0 * (1.0 / pixel.DFG.y - 1.0);
// #else
//     pixel.energyCompensation = float3(1.0,1.0,1.0);
// #endif
// #if !defined(SHADING_MODEL_CLOTH)
// #if defined(SHEEN_COLOR)
//     pixel.sheenDFG = Prefiltered_DFG(pixel.sheenPerceptualRoughness,NdotV).z;
//     pixel.sheenScaling = 1.0 - max(pixel.sheenColor.x,max(pixel.sheenColor.y,pixel.sheenColor.z)) * pixel.sheenDFG;
// #endif
// #endif
// }


void getPixelParams(const MaterialInputs material,out PixelParams pixel,const ShadingParameters shadingParameters) {
	float NdotV=clampNdotV(dot(shadingParameters.normalWS,shadingParameters.viewDir));
	float3 geometricNormal=shadingParameters.geometricNormalWS;

	// getCommonPixelParams(material,pixel);
	float4 baseColor=material.baseColor;

#if defined(SHADING_MODEL_SPECULAR_GLOSSINESS)
    // // This is from KHR_materials_pbrSpecularGlossiness.
    float3 specularColor = material.specularColor;
    float metallic = computeMetallicFromSpecularColor(specularColor);
    
    pixel.diffColor = computeDiffuseColor(baseColor, metallic);
    pixel.F0 = specularColor;
#elif !defined(SHADING_MODEL_CLOTH)
    pixel.diffColor = computeDiffuseColor(baseColor, material.metallic);
#if !defined(SHADING_MODEL_SUBSURFACE) && (!defined(REFLECTANCE) && defined(IOR))
    float reflectance = iorToF0(max(1.0, material.ior), 1.0);
#else
    // Assumes an interface from air to an IOR of 1.5 for dielectrics
    float reflectance = computeDielectricF0(material.reflectance);
#endif
    pixel.F0 = computeF0(baseColor, material.metallic, reflectance);
#else
    pixel.diffColor = baseColor.rgb;
    pixel.F0 = material.sheenColor;
	
#if defined(SUBSURFACE_COLOR)
    pixel.subsurfaceColor = material.subsurfaceColor;
#endif
	
#endif

// #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
// #if defined(REFRACTION)
//     // Air's Index of refraction is 1.000277 at STP but everybody uses 1.0
//     const float airIor = 1.0;
// #if !defined(IOR)
//     // [common case] ior is not set in the material, deduce it from F0
//     float materialor = f0ToIor(pixel.F0.g);
// #else
//     // if ior is set in the material, use it (can lead to unrealistic materials)
//     float materialor = max(1.0, material.ior);
// #endif
//     pixel.etaIR = airIor / materialor;  // air -> material
//     pixel.etaRI = materialor / airIor;  // material -> air
// #if defined(TRANSMISSION)
//     pixel.transmission = saturate(material.transmission);
// #else
//     pixel.transmission = 1.0;
// #endif
// #if defined(ABSORPTION)
// #if defined(THICKNESS) || defined(MICRO_THICKNESS)
//     pixel.absorption = max(vec3(0.0), material.absorption);
// #else
//     pixel.absorption = saturate(material.absorption);
// #endif
// #else
//     pixel.absorption = vec3(0.0);
// #endif
// #if defined(THICKNESS)
//     pixel.thickness = max(0.0, material.thickness);
// #endif
// #if defined(MICRO_THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
//     pixel.uThickness = max(0.0, material.microThickness);
// #else
//     pixel.uThickness = 0.0;
// #endif
// #endif
// #endif
	
	
	//getSheenPixelParams(material,pixel,geometricNormal)
#if defined(SHEEN_COLOR) && !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
    pixel.sheenColor = material.sheenColor;

    float sheenPerceptualRoughness = material.sheenRoughness;
    sheenPerceptualRoughness = clamp(sheenPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);

#if defined(GEOMETRIC_SPECULAR_AA)
    sheenPerceptualRoughness =
            normalFiltering(sheenPerceptualRoughness, geometricNormal);
#endif

    pixel.sheenPerceptualRoughness = sheenPerceptualRoughness;
    pixel.sheenRoughness = perceptualRoughnessToRoughness(sheenPerceptualRoughness);
#endif
	
	// getClearCoatPixelParams(material,pixel,geometricNormal);
#if defined(CLEAR_COAT)
    pixel.clearCoat = material.clearCoat;

    // Clamp the clear coat roughness to avoid divisions by 0
    float clearCoatPerceptualRoughness = material.clearCoatRoughness;
    clearCoatPerceptualRoughness =
            clamp(clearCoatPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);

#if defined(GEOMETRIC_SPECULAR_AA)
    clearCoatPerceptualRoughness =
            normalFiltering(clearCoatPerceptualRoughness, geometricNormal);
#endif
    pixel.clearCoatPerceptualRoughness = clearCoatPerceptualRoughness;
    pixel.clearCoatRoughness = perceptualRoughnessToRoughness(clearCoatPerceptualRoughness);

// #if defined(CLEAR_COAT_IOR_CHANGE)
//     // The base layer's f0 is computed assuming an interface from air to an IOR
//     // of 1.5, but the clear coat layer forms an interface from IOR 1.5 to IOR
//     // 1.5. We recompute f0 by first computing its IOR, then reconverting to f0
//     // by using the correct interface
//     pixel.f0 = mix(pixel.f0, f0ClearCoatToSurface(pixel.f0), pixel.clearCoat);
// #endif

#endif

	// getRoughnessPixelParams(material,pixel,geometricNormal);
	float perceptualRoughness=material.roughness;
	pixel.perceptualRoughnessUnclamped=perceptualRoughness;

#if defined(GEOMETRIC_SPECULAR_AA)
    perceptualRoughness = normalFiltering(perceptualRoughness, geometricNormal);
#endif
#if defined(CLEAR_COAT) && defined(CLEAR_COAT_ROUGHNESS)
    // This is a hack but it will do: the base layer must be at least as rough
    // as the clear coat layer to take into account possible diffusion by the
    // top layer
    float basePerceptualRoughness = max(perceptualRoughness, pixel.clearCoatPerceptualRoughness);
    perceptualRoughness = lerp(perceptualRoughness, basePerceptualRoughness, pixel.clearCoat);
#endif

    // Clamp the roughness to a minimum value to avoid divisions by 0 during lighting
    pixel.perceptualRoughness = clamp(perceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
    // Remaps the roughness to a perceptually linear roughness (roughness^2)
    pixel.roughness = perceptualRoughnessToRoughness(pixel.perceptualRoughness);

	
	//getSubsurfacePixelParams(material,pixel)
#if defined(SHADING_MODEL_SUBSURFACE)
    pixel.subsurfacePower = material.subsurfacePower;
    pixel.subsurfaceColor = material.subsurfaceColor;
    pixel.thickness = saturate(material.thickness);
#endif
    	
	// getAnisotropyPixelParams(material,pixel,shadingParameters);
#if defined(ANISOTROPY)
    float3 direction = material.anisotropyDirection;
    pixel.anisotropy = material.anisotropy;

	//glsl tangentToWorld*direction
    pixel.anisotropicT = normalize(mul(shadingParameters.tangentToWorld,direction));	
    pixel.anisotropicB = normalize(cross(geometricNormal, pixel.anisotropicT));
#endif
	
	// getEnergyCompensationPixelParams(material,pixel,NdotV);
	//[Lazarov 13] 
	// pixel.DFG=float3(Prefiltered_DFG_Approx(pixel.perceptualRoughness,NdotV),1.0);
	//DFG LUT 
	pixel.DFG=Prefiltered_DFG_CLOTH_LUT(pixel.perceptualRoughness,NdotV);
	
// #if !defined(SHADING_MODEL_CLOTH)
//     // Energy compensation for multiple scattering in a microfacet model
//     // See "Multiple-Scattering Microfacet BSDFs with the Smith Model"
//     pixel.energyCompensation = 1.0 + pixel.F0 * (1.0 / pixel.DFG.y - 1.0);
// #else
    pixel.energyCompensation = float3(1.0,1.0,1.0);
// #endif
	
#if !defined(SHADING_MODEL_CLOTH)
#if defined(SHEEN_COLOR)
    pixel.sheenDFG = Prefiltered_DFG_CLOTH_LUT(pixel.sheenPerceptualRoughness,NdotV).z;
    pixel.sheenScaling = 1.0 - max(pixel.sheenColor.x,max(pixel.sheenColor.y,pixel.sheenColor.z)) * pixel.sheenDFG;
#endif
#endif
}

// /**
//  * This function evaluates all lights one by one:
//  * - Image based lights (IBL)
//  * - Directional lights
//  * - Punctual lights
//  *
//  * Area lights are currently not supported.
//  *
//  * Returns a pre-exposed HDR RGBA color in linear space.
//  */
// vec4 evaluateLights(const MaterialInputs material) {
//     PixelParams pixel;
//     getPixelParams(material, pixel);
//
//     // Ideally we would keep the diffuse and specular components separate
//     // until the very end but it costs more ALUs on mobile. The gains are
//     // currently not worth the extra operations
//     vec3 color = vec3(0.0);
//
//     // We always evaluate the IBL as not having one is going to be uncommon,
//     // it also saves 1 shader variant
//     evaluateIBL(material, pixel, color);
//
// #if defined(VARIANT_HAS_DIRECTIONAL_LIGHTING)
//     evaluateDirectionalLight(material, pixel, color);
// #endif
//
// #if defined(VARIANT_HAS_DYNAMIC_LIGHTING)
//     evaluatePunctualLights(material, pixel, color);
// #endif
//
// #if defined(BLEND_MODE_FADE) && !defined(SHADING_MODEL_UNLIT)
//     // In fade mode we un-premultiply baseColor early on, so we need to
//     // premultiply again at the end (affects diffuse and specular lighting)
//     color *= material.baseColor.a;
// #endif
//
//     return vec4(color, computeDiffuseAlpha(material.baseColor.a));
// }
//
// void addEmissive(const MaterialInputs material, inout vec4 color) {
// #if defined(MATERIAL_HAS_EMISSIVE)
//     highp vec4 emissive = material.emissive;
//     highp float attenuation = mix(1.0, getExposure(), emissive.w);
//     color.rgb += emissive.rgb * (attenuation * color.a);
// #endif
// }
//
// /**
//  * Evaluate lit materials. The actual shading model used to do so is defined
//  * by the function surfaceShading() found in shading_model_*.fs.
//  *
//  * Returns a pre-exposed HDR RGBA color in linear space.
//  */
// vec4 evaluateMaterial(const MaterialInputs material) {
//     vec4 color = evaluateLights(material);
//     addEmissive(material, color);
//     return color;
// }

//Shading_Lit_Custom.hlsl
// vec3 customSurfaceShading(const MaterialInputs materialInputs,
//         const PixelParams pixel, const Light light, float visibility) {
//
//     LightData lightData;
//     lightData.colorIntensity = light.colorIntensity;
//     lightData.l = light.l;
//     lightData.NdotL = light.NoL;
//     lightData.worldPosition = light.worldPosition;
//     lightData.attenuation = light.attenuation;
//     lightData.visibility = visibility;
//
//     ShadingData shadingData;
//     shadingData.diffuseColor = pixel.diffuseColor;
//     shadingData.perceptualRoughness = pixel.perceptualRoughness;
//     shadingData.f0 = pixel.f0;
//     shadingData.roughness = pixel.roughness;
//
//     return surfaceShading(materialInputs, shadingData, lightData);
// }


#endif