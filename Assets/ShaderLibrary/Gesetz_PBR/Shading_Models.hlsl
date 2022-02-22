#ifndef GESETZ_SHADING_MODELS_INCLUDED
#define GESETZ_SHADING_MODELS_INCLUDED

#include "BRDF.hlsl"
#include "Lighting_Common.hlsl"

#include "UnityStandardBRDF.cginc"

//Standard
#if defined(SHEEN_COLOR)
half3 sheenLobe(const PixelParams pixel,
				float NdotV,float NdotL,float NdotH)
{
	float D=Distribution_Cloth(pixel.sheenRoughness,NdotH);
	float V=Visibility_Cloth(NdotV,NdotL);

	return (D*V)*pixel.sheenColor;
}
#endif

#if defined(CLEAR_COAT)
float3 ClearCoatLobe(const PixelParams pixel,const float3 H,
					float NdotH,float LdotH,out float Fcc)
{
#if defined(CLEAR_COAT_NORMAL) || defined(_NORMAL_MAP)
    // If the material has a normal map, we want to use the geometric normal
    // instead to avoid applying the normal map details to the clear coat layer
    float clearCoatNdotH = saturate(dot(clearCoatNormal, H));
#else
	float clearCoatNdotH=NdotH;
#endif

	float D=Distribution_ClearCoat(pixel.clearCoatRoughness,clearCoatNdotH,H);
	float V=Visibility_ClearCoat(LdotH);
	float F=F_Schlick(0.04,1.0,LdotH)*pixel.clearColor;

	Fcc=F;
	return D*V*F;
}
#endif


#if defined(ANISOTROPY)
float3 AnisotropicLobe(const PixelParams pixel,const float3 viewDir,const float3 L,
				const float3 H,float NdotV,float NdotL,float NdotH,float LdotH)
{
	float3 T=pixel.anisotropicT;
	float3 B=pixel.anisotropicB;
	float3 V=viewDir;

	float TdotV=dot(T,V);
	float BdotV = dot(B, V);
    float TdotL = dot(T, L);
    float BdotL = dot(B, L);
    float TdotH = dot(T, H);
    float BdotH = dot(B, H);

	//[Kulla 17], "Revisiting Physically Based Shading at Imageworks"
	float at=max(pixel.roughness*(1.0+pixel.anisotropy),MIN_ROUGHNESS);
	float ab=max(pixel.roughness*(1.0-pixel.anisotropy),MIN_ROUGHNESS);

	float D=Distribution_Anisotropic(at,ab,TdotH,BdotH,NdotH);
	float V=Visibility_Anisotropic(pixel.roughness,at,ab,TdotV,BdotV,TdotL,BdotL,NdotV, NdotL);
	float3 F=Fresnel(pixel.F0,LdotH);

	return (D*V)*F;
}
#endif

float3 IsotropicLobe(const PixelParams pixel,
				const float3 H,float NdotV,float NdotL,float NdotH,float LdotH)
{
	float D=Distribution(pixel.roughness,NdotH,H);
	float V=Visibility(pixel.roughness,NdotV,NdotL);
	float3 F=Fresnel(pixel.F0,LdotH);

	return (D*V)*F;
}

float3 DiffuseLobe(const PixelParams pixel, float NoV, float NoL, float LoH)
{
	return pixel.diffColor*Diffuse(pixel.roughness,NoV,NoL,LoH);
}

float SpecularTerm(const PixelParams pixel,
				const float3 H,float NdotV,float NdotL,float NdotH)
{
	float D=Distribution(pixel.roughness,NdotH,H);
	float V=Visibility(pixel.roughness,NdotV,NdotL);

	return D*V;
}
float3 DiffuseTerm(const PixelParams pixel, float NoV, float NoL, float LoH) {
    return Diffuse(pixel.roughness, NoV, NoL, LoH);
}

//Surface BRDF - Standard Model +(ClearCoat,Anisotropy,Sheen)
float4 GESETZ_BRDF_PBS(PixelParams pixel,
					float3 normal,float3 V,
					UnityLight light,UnityIndirect gi,float OneMinusReflectivity)
{
	float3 L=light.dir;

	//SafeNormalize
	float3 H=normalize(V+L);
	
	float NdotV=abs(dot(normal,V));
	float NdotL=saturate(dot(normal,L));
	float NdotH=saturate(dot(normal,H));
	float LdotH=saturate(dot(L,H));

#if defined(ANISOTROPY)
	float3 Fr=AnisotropicLobe(pixel,V,L,H,NdotV,NdotL,NdotH,LdotH);
#else
	float3 Fr=IsotropicLobe(pixel,H,NdotV,NdotL,NdotH,LdotH);
#endif
	float3 Fd=DiffuseLobe(pixel,NdotV,NdotL,LdotH);
//
// #if defined(REFRACTION)
// 	Fd*=(1.0-pixel.transmission);
// #endif
//
	float3 directcolor=Fd+Fr*pixel.energyCompensation;

#if defined(SHEEN_COLOR)
    color *= pixel.sheenScaling;
    color += sheenLobe(pixel, NdotV, NdotL, NdotH);
#endif

#if defined(CLEAR_COAT)
	float Fcc;
	float clearCoat=ClearCoatLobe(pixel,H,NdotH,LdotH,Fcc);

	float attenuation=1.0-Fcc;
// #if /*defined(NORMAL)||*/defined(_NORMAL_MAP)||defined(CLEAR_COAT_NORMAL)
// 	float clearCoatNdotL=saturate(dot());
// 	color+=clearCoat*clearCoatNdotL;
// 	
// #endif
	color*=attenuation;
	color+=ClearCoat;
#endif

	directcolor*=light.color*NdotL;
	float3 indirectcolor=pixel.diffColor*gi.diffuse+pixel.F0*gi.specular;
	
	return float4(directcolor+indirectcolor,1.0);

	//BRDF1_Unity_PBS
	// float unity_diffuseTerm=DisneyDiffuse(NdotV,NdotL,LdotH,pixel.perceptualRoughness)*NdotL;
 //
	// float V=SmithGGXVisibilityTerm(NdotL,NdotV,pixel.roughness);
	// float D=GGXTerm(NdotH,pixel.roughness);
	//
	// float unity_specularTerm=V*D*PI;
	// unity_specularTerm=max(0.0,unity_specularTerm*NdotL);
 //
	// float surfaceReduction=1.0/(pixel.roughness*pixel.roughness+1.0);
 //    unity_specularTerm *= any(pixel.F0) ? 1.0 : 0.0;
	// float grazingTerm=saturate(1.0-pixel.roughness+(1-OneMinusReflectivity));
 //
	// return float4(pixel.diffColor*(gi.diffuse+light.color*unity_diffuseTerm)+
	// unity_specularTerm*light.color*FresnelTerm(pixel.F0,LdotH)+
	// surfaceReduction*gi.specular*FresnelLerp(pixel.F0,grazingTerm,NdotV),1.0);
}

// //Cloth
// float4 GESETZ_CLOTH_PBS(half3 diffColor,half3 specColor,half oneMinusReflectivity,half smothness,
// 					float3 normal,float3 viewDir,
// 					UnityLight light,UnityIndirect gi)
// {
// 	float3 H=normalize(viewDir+light.dir);
//
// 	float NdotL=light.ndotl;
// 	float NdotH=saturate(dot(normal,H));
// 	float LdotH=saturate(dot(light.dir,H));
// 	//Specular BRDF
// 	float D;
// 	float V;
// 	float3 F;
//
// 	float3 Fr=(D*V)*F;
//
// 	//Diffuse BRDF
// 	float diffuse;
// //#if defined(SUBSURFACE_COLOR)
// 	diffuse*=Fd_Wrap(dot(normal,light.dir),0.5);
// //endif
// 	float3 Fd=diffuse*diffColor;
//
// 	float3 color=Fd+Fr;
// 	
// 	return color;
// }

//Subsurface
// TODO



#endif