#include "Assets/ShaderLibrary/Example/Lightmapping.cginc"
#ifndef GESETZ_MATERIALS_INPUT_INCLUDED
#define GESETZ_MATERIALS_INPUT_INCLUDED

#include "BRDF.hlsl"
#include "Lighting_Common.hlsl"

#if defined(SHADING_MODEL_CLOTH)
#if !defined(SUBSURFACE_COLOR)
    #define MATERIAL_CAN_SKIP_LIGHTING
#endif
#elif defined(SHADING_MODEL_SUBSURFACE) || defined(CUSTOM_SURFACE_SHADING)
    // Cannot skip lighting
#else
    #define MATERIAL_CAN_SKIP_LIGHTING
#endif

//Materials_Input.hlsl
// #if defined(MATERIAL_HAS_CUSTOM_SURFACE_SHADING)
// /** @public-api */
// struct LightData {
//     float4  colorIntensity;
//     float3  l;
//     float NdotL;
//     float3  worldPosition;
//     float attenuation;
//     float visibility;
// };
//
// /** @public-api */
// struct ShadingData {
//     float3  diffuseColor;
//     float perceptualRoughness;
//     float3  f0;
//     float roughness;
// };
// #endif

struct MaterialInputs
{
    float4  baseColor;
    float roughness;
#if !defined(SHADING_MODEL_CLOTH) 
    float metallic;
    float reflectance;
#endif
    float ambientOcclusion;
    float3  emissive;
	

	
 #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
 #if defined(SHEEN_COLOR)
     float3 sheenColor;
     float sheenRoughness;
 #endif
 #endif

 #if defined(CLEAR_COAT)
     float clearCoat;
    float clearCoatRoughness;
 #endif
 
 #if defined(ANISOTROPY)
     float anisotropy;
    float3  anisotropyDirection;
#endif
	
#if defined(SHADING_MODEL_SUBSURFACE) || defined(REFRACTION)
    float thickness;
#endif
#if defined(SHADING_MODEL_SUBSURFACE)
    float subsurfacePower;
    float3  subsurfaceColor;
#endif

#if defined(SHADING_MODEL_CLOTH)
    float3  sheenColor;
#if defined(SUBSURFACE_COLOR)
    float3  subsurfaceColor;
#endif
#endif


// #if defined(NORMAL)
//     float3  normal;
// #endif
// #if defined(BENT_NORMAL)
//     float3  bentNormal;
// #endif
// #if defined(CLEAR_COAT) && defined(CLEAR_COAT_NORMAL)
//     float3  clearCoatNormal;
// #endif

// #if defined(POST_LIGHTING_COLOR)
//     float4  postLightingColor;
// #endif
	
// #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
// #if defined(REFRACTION)
// #if defined(ABSORPTION)
//     float3 absorption;
// #endif
// #if defined(TRANSMISSION)
//     float transmission;
// #endif
// #if defined(IOR)
//     float ior;
// #endif
// #if defined(THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
//     float microThickness;
// #endif
// #elif !defined(SHADING_MODEL_SPECULAR_GLOSSINESS)
// #if defined(IOR)
//     float ior;
// #endif
// #endif
// #endif
};
void InitMaterialInputs(out MaterialInputs material)
{
	material.baseColor = float4(1.0,1.0,1.0,1.0);
    material.roughness = 1.0;

#if !defined(SHADING_MODEL_CLOTH)
    material.metallic = 0.0;
    material.reflectance = 0.5;
#endif
    material.ambientOcclusion = 1.0;
    material.emissive = float3(0.0,0.0,0.0);

	
 #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
 #if defined(SHEEN_COLOR)
     material.sheenColor = float3(0.0,0.0,0.0);
     material.sheenRoughness = 0.0;
 #endif
 #endif
 
 #if defined(CLEAR_COAT)
     material.clearCoat = 1.0;
     material.clearCoatRoughness = 0.0;
 #endif
 
 #if defined(ANISOTROPY)
     material.anisotropy = 0.0;
     material.anisotropyDirection = float3(1.0, 0.0, 0.0);
 #endif
 
 #if defined(SHADING_MODEL_SUBSURFACE) || defined(REFRACTION)
     material.thickness = 0.5;
 #endif
 #if defined(SHADING_MODEL_SUBSURFACE)
     material.subsurfacePower = 12.234;
     material.subsurfaceColor = float3(1.0,1.0,1.0);
 #endif
 
 #if defined(SHADING_MODEL_CLOTH)
     material.sheenColor = sqrt(material.baseColor.rgb);
 #if defined(SUBSURFACE_COLOR)
     material.subsurfaceColor = float3(0.0,0.0,0.0);
 #endif
 #endif


 // #if defined(NORMAL)
 //     material.normal = float3(0.0, 0.0, 1.0);
 // #endif
 // #if defined(BENT_NORMAL)
 //     material.bentNormal = float3(0.0, 0.0, 1.0);
 // #endif

 // #if defined(CLEAR_COAT) && defined(CLEAR_COAT_NORMAL)
 //     material.clearCoatNormal = float3(0.0, 0.0, 1.0);
 // #endif

 // #if defined(POST_LIGHTING_COLOR)
 //     material.postLightingColor = float4(0.0,0.0,0.0,0.0);
 // #endif

 // #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
 // #if defined(REFRACTION)
 // #if defined(ABSORPTION)
 //     material.absorption = float3(0.0, 0.0, 0.0);
 // #endif
 // #if defined(TRANSMISSION)
 //     material.transmission = 1.0;
 // #endif
 // #if defined(IOR)
 //     material.ior = 1.5;
 // #endif
 // #if defined(MICRO_THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
 //     material.microThickness = 0.0;
 // #endif
 // 	
 // #elif !defined(SHADING_MODEL_SPECULAR_GLOSSINESS)
 // #if defined(MATERIAL_HAS_IOR)
 //     material.ior = 1.5;
 // #endif
 // #endif
 // #endif
}

//Move to Material_getters.hlsl

float _Anisotropy;
sampler2D _AnisotropyDirection;

float GetAnisotropy()
{
#if defined(ANISOTROPY)
	return  _Anisotropy;
#endif
}

float3 GetAnisotropyDirection(Interpolators i)
{
#if defined(ANISOTROPY)
	return tex2D(_AnisotropyDirection,UV_FUNCTION(i).xy);
#endif
}


float _ClearCoat;
float _ClearCoatRoughness;

float GetClearCoat(Interpolators i)
{
	#if defined(CLEARCOAT_MAP)
		return tex2D(_ClearCoat_Map, UV_FUNCTION(i).xy).r;
	#else
		return _ClearCoat;
	#endif
}

float GetClearCoatRoughness(){
#if defined(CLEAR_COAT)
     return _ClearCoatRoughness;
#endif
}

sampler2D _ClearCoatNormal;
float3 GetClearCoatNormalTS(Interpolators i)
{
	float3 normal=float3(0.0,0.0,1.0);
#if defined(CLEAR_COAT_NORMAL)
	normal=tex2D(_ClearCoat_NormalMap, UV_FUNCTION(i).xy);
#endif
	return normal;
}

float3 _SheenColor;
float _SheenRoughness;

float3 GetSheenColor()
{
     return _SheenColor;
}

float GetsheenRoughness()
{
     return _SheenRoughness;
}

float3 _SubSurfaceColor;

float3 GetSubSurfaceColor()
{
    return _SubSurfaceColor;
}

float _SubSurfacePower;
float _Thickness;
float GetSubSurfacePower()
{
    return _SubSurfacePower;
}
float GetThickness()
{
    return _Thickness;
}


void prepareMaterial(inout MaterialInputs material,Interpolators i)
{
	//Standard
	material.baseColor=float4(GetAlbedo(i),GetAlpha(i));
	material.emissive=GetEmission(i);
	material.ambientOcclusion=GetOcclusion(i);
	material.roughness=GetRoughness(i);
	
#if !defined(SHADING_MODEL_CLOTH)
    material.metallic=GetMetallic(i);
    material.reflectance=GetReflectance();
#endif

#if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
#if defined(SHEEN_COLOR)
     material.sheenColor = GetSheenColor();
     material.sheenRoughness = GetsheenRoughness();
#endif
#endif
 
 #if defined(CLEAR_COAT)
     material.clearCoat = GetClearCoat(i);
     material.clearCoatRoughness =GetClearCoatRoughness();
 #endif
 
 #if defined(ANISOTROPY)
     material.anisotropy = GetAnisotropy();
     material.anisotropyDirection = GetAnisotropyDirection(i);
 #endif

#if defined(SHADING_MODEL_SUBSURFACE) || defined(REFRACTION)
    material.thickness=GetThickness();
#endif
#if defined(SHADING_MODEL_SUBSURFACE)
    material.subsurfacePower=GetSubSurfacePower();
    material.subsurfaceColor=GetSubSurfaceColor();
#endif

#if defined(SHADING_MODEL_CLOTH)
    material.sheenColor = GetSheenColor();
#if defined(SUBSURFACE_COLOR)
    material.subsurfaceColor=GetSubSurfaceColor();
#endif
#endif



}




#endif