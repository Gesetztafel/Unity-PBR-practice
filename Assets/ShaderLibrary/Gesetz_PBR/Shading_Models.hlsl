#ifndef GESETZ_SHADING_MODELS_INCLUDED
#define GESETZ_SHADING_MODELS_INCLUDED

#include "BRDF.hlsl"
#include "Lighting_Common.hlsl"

#include "UnityStandardBRDF.cginc"

//Standard
#if defined(SHEEN_COLOR)
float3 sheenLobe(const PixelParams pixel,
				float NdotV,float NdotL,float NdotH)
{
	float D=Distribution_Cloth(pixel.sheenRoughness,NdotH);
	float V=Visibility_Cloth(NdotV,NdotL);

	return (D*V)*pixel.sheenColor;
}
#endif

#if defined(CLEAR_COAT)
float ClearCoatLobe(const PixelParams pixel,const float3 H,
					float NdotH,float LdotH,out float Fcc,const float3 clearCoatNormalWS)
{
#if defined(CLEAR_COAT_NORMAL) || defined(_NORMAL_MAP)
    // If the material has a normal map, we want to use the geometric normal
    // instead to avoid applying the normal map details to the clear coat layer
    float clearCoatNdotH = saturate(dot(clearCoatNormalWS, H));
#else
	float clearCoatNdotH=NdotH;
#endif

	float D=Distribution_ClearCoat(pixel.clearCoatRoughness,clearCoatNdotH,H);
	float V=Visibility_ClearCoat(LdotH);
	float F=F_Schlick(LdotH,0.04,1.0)*pixel.clearCoat;

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

	float TdotV=dot(T,viewDir);
	float BdotV = dot(B, viewDir);
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
float4 GESETZ_BRDF_PBS(PixelParams pixel,ShadingParameters shadingParameters,
					UnityLight light)
{
	float3 L=light.dir;
	float3 viewDir=shadingParameters.viewDir;
	float3 normal=shadingParameters.normalWS;
	
	//SafeNormalize
	float3 H=normalize(viewDir+L);
	
	float NdotV=shadingParameters.NdotV;
	float NdotL=saturate(dot(normal,L));
	float NdotH=saturate(dot(normal,H));
	float LdotH=saturate(dot(L,H));

#if defined(ANISOTROPY)
	float3 Fr=AnisotropicLobe(pixel,viewDir,L,H,NdotV,NdotL,NdotH,LdotH);
#else
	float3 Fr=IsotropicLobe(pixel,H,NdotV,NdotL,NdotH,LdotH);
#endif
	float3 Fd=DiffuseLobe(pixel,NdotV,NdotL,LdotH);

#if defined(REFRACTION)
	Fd*=(1.0-pixel.transmission);
#endif

	float3 color=Fd+Fr*pixel.energyCompensation;

#if defined(SHEEN_COLOR)
    color *= pixel.sheenScaling;
    color += sheenLobe(pixel, NdotV, NdotL, NdotH);
#endif

#if defined(CLEAR_COAT)
	float Fcc;
	float3 clearCoatNormalWS=shadingParameters.clearCoatNormalWS;
	
	float clearCoat=ClearCoatLobe(pixel,H,NdotH,LdotH,Fcc,clearCoatNormalWS);
	float attenuation=1.0-Fcc;
#if defined(_NORMAL_MAP)||defined(CLEAR_COAT_NORMAL)
	float clearCoatNdotL=saturate(dot(clearCoatNormalWS,L));
	color+=clearCoat*clearCoatNdotL;
	
	return float4((color*light.color),1.0);
#endif
	color*=attenuation;
	color+=clearCoat;
#endif

	//Compare to Unity *PI
	color*=light.color*NdotL;
	
	return float4(color,1.0);

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
	// return float4(
	// //Direct Diffuse
	// pixel.diffColor*light.color*unity_diffuseTerm+
	// // Indirect Diffuse
	// pixel.diffColor*gi.diffuse+
	// //Direct Specular
	// unity_specularTerm*light.color*FresnelTerm(pixel.F0,LdotH)+
	// // Indirect Specular 
	// surfaceReduction*gi.specular*FresnelLerp(pixel.F0,grazingTerm,NdotV)
	// ,1.0);
}

//Cloth
float4 GESETZ_CLOTH_PBS(PixelParams pixel,ShadingParameters shadingParameters,
					UnityLight light)
{
	float3 L=light.dir;
	float3 viewDir=shadingParameters.viewDir;
	float3 normal=shadingParameters.normalWS;
	
	//SafeNormalize
	float3 H=normalize(viewDir+L);
	
	float NdotV=max(dot(normal,viewDir),MIN_N_DOT_V);
	float NdotL=saturate(dot(normal,L));
	float NdotH=saturate(dot(normal,H));
	float LdotH=saturate(dot(L,H));
	//Specular BRDF
	float D=Distribution_Cloth(pixel.roughness,NdotH);
	float V=Visibility_Cloth(NdotV,NdotL);
	float3 F=pixel.F0;

	float3 Fr=(D*V)*F;

	//Diffuse BRDF
	float diffuse=Diffuse(pixel.roughness,NdotV,NdotL,LdotH);
#if defined(SUBSURFACE_COLOR)
	diffuse*=Fd_Wrap(dot(normal,light.dir),0.5);
#endif
	float3 Fd=diffuse*pixel.diffColor;

#if defined(SUBSURFACE_COLOR)
    // Cheap subsurface scatter
    Fd *= saturate(pixel.subsurfaceColor + NdotL);
    // We need to apply NoL separately to the specular lobe since we already took
    // it into account in the diffuse lobe
    float3 color = Fd + Fr * NdotL;
    color *= light.color;
#else
    float3 color = Fd + Fr;
    color *= light.color * NdotL;
#endif
	
	return float4(color,1.0);
}

//Subsurface

float4 GESETZ_SUBSURFACE_PBS(PixelParams pixel,ShadingParameters shadingParameters,UnityLight light,float occlusion)
{
	float3 L=light.dir;
	float3 viewDir=shadingParameters.viewDir;
	float3 normal=shadingParameters.normalWS;
	
	//SafeNormalize
	float3 H=normalize(viewDir+L);
	
	float NdotV=max(dot(normal,viewDir),MIN_N_DOT_V);
	float NdotL=saturate(dot(normal,L));
	float NdotH=saturate(dot(normal,H));
	float LdotH=saturate(dot(L,H));

	float3 Fr=0.0;
	if(NdotL>0.0)
	{
		// specular BRDF
		float D=Distribution(pixel.roughness,NdotH,H);
		float V=Visibility(pixel.roughness,NdotV,NdotL);
		float3 F=Fresnel(pixel.F0,LdotH);
		
		Fr=(D*V)*F*pixel.energyCompensation;
	}

	// diffuse BRDF
	float3 Fd=pixel.diffColor*Diffuse(pixel.roughness,NdotV,NdotL,LdotH);
	
	// NoL does not apply to transmitted light
	float3 color=(Fd+Fr)*(NdotL*occlusion);
	// subsurface scattering
    // Use a spherical gaussian approximation of pow() for forwardScattering
    // We could include distortion by adding shading_normal * distortion to light.l

#if defined(SHADING_MODEL_SUBSURFACE)
	float scatterVdotH=saturate(dot(viewDir,-L));
	float fowardScatter=exp2(scatterVdotH*pixel.subsurfacePower-pixel.subsurfacePower);
	float backScatter=saturate(NdotL*pixel.thickness+(1.0-pixel.thickness))*0.5;
	float subsurface=lerp(backScatter,1.0,fowardScatter)*(1.0-pixel.thickness);
	color+=pixel.subsurfaceColor*(subsurface*Fd_Lambert());
#endif
	
	// TODO: apply occlusion to the transmitted light
	return float4(color*light.color,1.0);
}

#endif