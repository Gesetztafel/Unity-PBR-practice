
#ifndef GESETZ_INDIRECT_LIGHT_INCLUDED
#define GESETZ_INDIRECT_LIGHT_INCLUDED

#include "BRDF.hlsl"
#include "Shading_Config.hlsl"
#include "Lighting_Common.hlsl"
#include "Materials_Input.hlsl"
#include "Common_Shading.hlsl"
#include "Ambient_Occlusion.hlsl"
#include "UnityGlobalIllumination.cginc"

//Diffuse BRDF 
//IBL Irradiance 
// float3 IrradianceSH(float4 SHCoefficients[9], float3 n) {
//     return max(
//           SHCoefficients[0]
// #if SPHERICAL_HARMONICS_BANDS >= 2
//         + SHCoefficients[1] * (n.y)
//         + SHCoefficients[2] * (n.z)
//         + SHCoefficients[3] * (n.x)
// #endif
// #if SPHERICAL_HARMONICS_BANDS >= 3
//         + SHCoefficients[4] * (n.y * n.x)
//         + SHCoefficients[5] * (n.y * n.z)
//         + SHCoefficients[6] * (3.0 * n.z * n.z - 1.0)
//         + SHCoefficients[7] * (n.z * n.x)
//         + SHCoefficients[8] * (n.x * n.x - n.y * n.y)
// #endif
//         ,0.0);
// }

// IBL specular
// float perceptualRoughnessToLod(float perceptualRoughness) {
//     // The mapping below is a quadratic fit for log2(perceptualRoughness)+iblRoughnessOneLevel when
//     // iblRoughnessOneLevel is 4. We found empirically that this mapping works very well for
//     // a 256 cubemap with 5 levels used. But also scales well for other iblRoughnessOneLevel values.
//     return frameUniforms.iblRoughnessOneLevel * perceptualRoughness * (2.0 - perceptualRoughness);
// }
//
// float3 getSpecularDominantDirection(const float3 n, const float3 r, float roughness) {
//     return lerp(r, n, roughness * roughness);
// }
//
// float3 getReflectedVector(const PixelParams pixel, const float3 n) {
// #if defined(ANISOTROPY)
//     float3 r = getReflectedVector(pixel, shading_view, n);
// #else
//     float3 r = shading_reflected;
// #endif
//     return getSpecularDominantDirection(n, r, pixel.roughness);
// }

//Prefiltered importance sampling
// float2 Hammersley(uint index)
// {
// 	const uint numSamples=uint(IBL_INTEGRATION_IMPORTANCE_SAMPLING_COUNT);
// 	const float invNumSamples = 1.0 / float(numSamples);
//     const float tof = 0.5 / float(0x80000000U);
//     uint bits = index;
//     bits = (bits << 16u) | (bits >> 16u);
//     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
//     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
//     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
//     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
//     return float2(float(index) * invNumSamples, float(bits) * tof);
// }
//
// float3 ImportanceSampling_NDF_D_GGX(float2 u,float roughness)
// {
// 	float a_2=roughness*roughness;
// 	float phi=2.0*PI*u.x;
// 	float cosTheta2=(1.0-u.y)/(1.0+(a_2-1.0)*u.y);
// 	float cosTheta=sqrt(cosTheta2);
// 	float sinTheta=sqrt(1.0-cosTheta2);
//
// 	return float3(cos(phi)*sinTheta,sin(phi)*sinTheta,cosTheta);
// }
//
// float3 HemiSphereCosSample(float2 u)
// {
// 	float phi = 2.0f * PI * u.x;
//     float cosTheta2 = 1.0 - u.y;
//     float cosTheta = sqrt(cosTheta2);
//     float sinTheta = sqrt(1.0 - cosTheta2);
//     return float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
// }
//
// float ImportanceSampling_V_NDF_GGX(float2 u,float roughness,float3 v)
// {
// 	// See: "A Simpler and Exact Sampling Routine for the GGX Distribution of Visible Normals", Eric Heitz
//     float alpha = roughness;
//
//     // stretch view
//     v = normalize(float3(alpha * v.x, alpha * v.y, v.z));
//
//     // orthonormal basis
//     float3 up = abs(v.z) < 0.9999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
//     float3 t = normalize(cross(up, v));
//     float3 b = cross(t, v);
//
//     // sample point with polar coordinates (r, phi)
//     float a = 1.0 / (1.0 + v.z);
//     float r = sqrt(u.x);
//     float phi = (u.y < a) ? u.y / a * PI : PI + (u.y - a) / (1.0 - a) * PI;
//     float p1 = r * cos(phi);
//     float p2 = r * sin(phi) * ((u.y < a) ? 1.0 : v.z);
//
//     // compute normal
//     float3 h = p1 * t + p2 * b + sqrt(max(0.0, 1.0 - p1*p1 - p2*p2)) * v;
//
//     // unstretch
//     h = normalize(float3(alpha * h.x, alpha * h.y, max(0.0, h.z)));
//     return h;
// }
//
// float PrefilteredImportanceSampling(float ipdf, float omegaP) {
//     // See: "Real-time Shading with Filtered Importance Sampling", Jaroslav Krivanek
//     // Prefiltering doesn't work with anisotropy
//     const float numSamples = float(IBL_INTEGRATION_IMPORTANCE_SAMPLING_COUNT);
//     const float invNumSamples = 1.0 / float(numSamples);
//     const float K = 4.0;
//     float omegaS = invNumSamples * ipdf;
//     float mipLevel = log2(K * omegaS / omegaP) * 0.5;    // log4
//     return mipLevel;
// }
//
//
// #define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w) * _ScreenParams.xy)

// Pre-integration
// float3 IntegrateSpecularIBL(
// 	const PixelParams pixel, 
//     const float3 n, const float3 v, const float NdotV
// )
// {
// 	const uint numSamples = uint(IBL_INTEGRATION_IMPORTANCE_SAMPLING_COUNT);
//     const float invNumSamples = 1.0 / float(numSamples);
//     const float3 up = float3(0.0, 0.0, 1.0);
//     //a real tangent space tangent space
// 	float3x3 T;
//     T[0] = normalize(cross(up, n));
//     T[1] = cross(n, T[0]);
//     T[2] = n;
//
//     // Random rotation around N per pixel
// 	const float3 m = float3(0.06711056, 0.00583715, 52.9829189);
//     float a = 2.0 * PI * frac(m.z * frac(dot(gl_FragCoord.xy, m.xy)));
//     float c = cos(a);
//     float s = sin(a);
//     float3x3 R;
//     R[0] = float3( c, s, 0);
//     R[1] = float3(-s, c, 0);
//     R[2] = float3( 0, 0, 1);
//     T *= R;
//
// 	float roughness = pixel.roughness;
//     float dim = float(textureSize(light_iblSpecular, 0).x);
//     float omegaP = (4.0 * PI) / (6.0 * dim * dim);
//
// 	float3 indirectSpecular = float3(0.0,0.0,0.0);
//     for (uint i = 0u; i < numSamples; i++) {
//         float2 u = Hammersley(i);
//         float3 h = T * ImportanceSampling_NDF_D_GGX(u, roughness);
//
//         // Since anisotropy doesn't work with prefiltering, we use the same "faux" anisotropy
//         // we do when we use the prefiltered cubemap
//         float3 l = getReflectedVector(pixel, v, h);
//
//         // Compute this sample's contribution to the brdf
//         float NoL = saturate(dot(n, l));
//         if (NoL > 0.0) {
//             float NoH = dot(n, h);
//             float LoH = saturate(dot(l, h));
//
//             // PDF inverse (we must use D_GGX() here, which is used to generate samples)
//             float ipdf = (4.0 * LoH) / (D_GGX(roughness, NoH, h) * NoH);
//             float mipLevel = PrefilteredImportanceSampling(ipdf, omegaP);
//         	
//             float3 L = decodeDataForIBL(textureLod(light_iblSpecular, l, mipLevel));
//
//             float D = Distribution(roughness, NoH, h);
//             float V = Visibility(roughness, NdotV, NoL);
//             float3 F = Fresnel(pixel.F0, LoH);
//             float3 Fr = F * (D * V * NoL * ipdf * invNumSamples);
//
//             indirectSpecular += (Fr * L);
//         }
//     }
//
//     return indirectSpecular;
// }
// float3 IntegrateDiffuseIBL(
// 		const PixelParams pixel, float3 n, float3 v
// )
// {
// 	const uint numSamples = uint(IBL_INTEGRATION_IMPORTANCE_SAMPLING_COUNT);
//     const float invNumSamples = 1.0 / float(numSamples);
//     const float3 up = float3(0.0, 0.0, 1.0);
//     //a real tangent space tangent space
// 	float3x3 T;
//     T[0] = normalize(cross(up, n));
//     T[1] = cross(n, T[0]);
//     T[2] = n;
//
//     // Random rotation around N per pixel
// 	const float3 m = float3(0.06711056, 0.00583715, 52.9829189);
//     float a = 2.0 * PI * frac(m.z * frac(dot(gl_FragCoord.xy, m.xy)));
//     float c = cos(a);
//     float s = sin(a);
//     float3x3 R;
//     R[0] = float3( c, s, 0);
//     R[1] = float3(-s, c, 0);
//     R[2] = float3( 0, 0, 1);
//     T *= R;
//
//     float dim = float(textureSize(light_iblSpecular, 0).x);
//     float omegaP = (4.0 * PI) / (6.0 * dim * dim);
//
//     float3 indirectDiffuse = float3(0.0,0.0,0.0);
//     for (uint i = 0u; i < numSamples; i++) {
//         float2 u = Hammersley(i);
//         float3 h = T * HemiSphereCosSample(u);
//
//         // Since anisotropy doesn't work with prefiltering, we use the same "faux" anisotropy
//         // we do when we use the prefiltered cubemap
//         float3 l = getReflectedVector(pixel, v, h);
//
//         // Compute this sample's contribution to the brdf
//         float NoL = saturate(dot(n, l));
//         if (NoL > 0.0) {
//             // PDF inverse (we must use D_GGX() here, which is used to generate samples)
//             float ipdf = PI / NoL;
//             // we have to bias the mipLevel (+1) to help with very strong highlights
//             float mipLevel = PrefilteredImportanceSampling(ipdf, omegaP) + 1.0;
//             float3 L = decodeDataForIBL(textureLod(light_iblSpecular, l, mipLevel));
//             indirectDiffuse += L;
//         }
//     }
//
//     return indirectDiffuse * invNumSamples; // we bake 1/PI here, which cancels out
// }

// void evaluateIBL(const ExtendedMaterialInputs material, const PixelParams pixel, inout float3 color) {
//     // specular layer
//     float3 Fr = float3(0.0f,0.0f,0.0f);
//
//     SSAOInterpolationCache interpolationCache;
// #if defined(BLEND_MODE_OPAQUE) || defined(BLEND_MODE_MASKED) || defined(MATERIAL_HAS_REFLECTIONS)
//     interpolationCache.uv = uvToRenderTargetUV(getNormalizedViewportCoord().xy);
// #endif
//     screen-space reflections
// #if defined(MATERIAL_HAS_REFLECTIONS)
//     vec4 ssrFr = vec4(0.0f);
// #if defined(BLEND_MODE_OPAQUE) || defined(BLEND_MODE_MASKED)
//     // do the uniform based test first
//     if (frameUniforms.ssrDistance > 0.0f) {
//         // There is no point doing SSR for very high roughness because we're limited by the fov
//         // of the screen, in addition it doesn't really add much to the final image.
//         // TODO: maybe make this a parameter
//         const float maxPerceptualRoughness = sqrt(0.5);
//         if (pixel.perceptualRoughness < maxPerceptualRoughness) {
//             // distance to camera plane
//             const float invLog2sqrt5 = 0.8614;
//             float d = -mulMat4x4Float3(getViewFromWorldMatrix(), getWorldPosition()).z;
//             float lod = max(0.0, (log2(pixel.roughness / d) + frameUniforms.refractionLodOffset) * invLog2sqrt5);
// #if !defined(MATERIAL_HAS_REFRACTION)
//             // this is temporary, until we can access the SSR buffer when we have refraction
//             ssrFr = textureLod(light_ssr, interpolationCache.uv, lod);
// #endif
//         }
//     }
// #else // BLEND_MODE_OPAQUE
//     // TODO: for blended transparency, we have to ray-march here (limited to mirror reflections)
// #endif
// #else // MATERIAL_HAS_REFLECTIONS
//     const vec4 ssrFr = vec4(0.0f);
// #endif
//
//     // If screen-space reflections are turned on and have full contribution (ssr.a == 1.0f), then we
//     // skip sampling the IBL down below.
//
// #if IBL_INTEGRATION == IBL_INTEGRATION_PREFILTERED_CUBEMAP
//     vec3 E = specularDFG(pixel);
//     if (ssrFr.a < 1.0f) { // prevent reading the IBL if possible
//         vec3 r = getReflectedVector(pixel, shading_normal);
//         Fr = E * prefilteredRadiance(r, pixel.perceptualRoughness);
//     }
// #elif IBL_INTEGRATION == IBL_INTEGRATION_IMPORTANCE_SAMPLING
//     vec3 E = vec3(0.0); // TODO: fix for importance sampling
//     if (ssrFr.a < 1.0f) { // prevent evaluating the IBL if possible
//         Fr = isEvaluateSpecularIBL(pixel, shading_normal, shading_view, shading_NoV);
//     }
// #endif
//
//     // Ambient occlusion
//     float ssao = evaluateSSAO(interpolationCache);
//     float diffuseAO = min(material.ambientOcclusion, ssao);
//     float specularAO = specularAO(shading_NoV, diffuseAO, pixel.roughness, interpolationCache);
//
//     vec3 specularSingleBounceAO = singleBounceAO(specularAO) * pixel.energyCompensation;
//     Fr *= specularSingleBounceAO;
// #if defined(MATERIAL_HAS_REFLECTIONS)
//     ssrFr.rgb *= specularSingleBounceAO;
// #endif
//
//     // diffuse layer
//     float diffuseBRDF = singleBounceAO(diffuseAO); // Fd_Lambert() is baked in the SH below
//     evaluateClothIndirectDiffuseBRDF(pixel, diffuseBRDF);
//
// #if defined(MATERIAL_HAS_BENT_NORMAL)
//     vec3 diffuseNormal = shading_bentNormal;
// #else
//     vec3 diffuseNormal = shading_normal;
// #endif
//
// #if IBL_INTEGRATION == IBL_INTEGRATION_PREFILTERED_CUBEMAP
//     vec3 diffuseIrradiance = diffuseIrradiance(diffuseNormal);
// #elif IBL_INTEGRATION == IBL_INTEGRATION_IMPORTANCE_SAMPLING
//     vec3 diffuseIrradiance = isEvaluateDiffuseIBL(pixel, diffuseNormal, shading_view);
// #endif
//     vec3 Fd = pixel.diffuseColor * diffuseIrradiance * (1.0 - E) * diffuseBRDF;
//
//     // subsurface layer
//     evaluateSubsurfaceIBL(pixel, diffuseIrradiance, Fd, Fr);
//
//     // extra ambient occlusion term for the base and subsurface layers
//     multiBounceAO(diffuseAO, pixel.diffuseColor, Fd);
//     multiBounceSpecularAO(specularAO, pixel.f0, Fr);
//
//     // sheen layer
//     evaluateSheenIBL(pixel, diffuseAO, interpolationCache, Fd, Fr);
//
//     // clear coat layer
//     evaluateClearCoatIBL(pixel, diffuseAO, interpolationCache, Fd, Fr);
//
//     Fr *= frameUniforms.iblLuminance;
//     Fd *= frameUniforms.iblLuminance;
//
// #if defined(MATERIAL_HAS_REFRACTION)
//     vec3 Ft = evaluateRefraction(pixel, shading_normal, E);
//     Ft *= pixel.transmission;
//     Fd *= (1.0 - pixel.transmission);
// #endif
//
// #if defined(MATERIAL_HAS_REFLECTIONS)
//     Fr = Fr * (1.0 - ssrFr.a) + (E * ssrFr.rgb);
// #endif
//
//     // Combine all terms
//     // Note: iblLuminance is already premultiplied by the exposure
//
//     color.rgb += Fr + Fd;
// #if defined(MATERIAL_HAS_REFRACTION)
//     color.rgb += Ft;
// #endif
// }


sampler2D _DFG;
sampler2D _DFG_CLOTH;

float3 Prefiltered_DFG_CLOTH_LUT(float lod,float NdotV)
{
	return tex2D(_DFG_CLOTH,float2(NdotV,lod)).rgb;
}

float3 Prefiltered_DFG_LUT(float lod,float NdotV)
{
	return tex2D(_DFG,float2(NdotV,lod)).rgb;
}

float3 Prefiltered_DFG(float perceptualRoughness,float NdotV)
{
	return Prefiltered_DFG_LUT(perceptualRoughness,NdotV);
}

float2 Prefiltered_DFG_Approx(float perceptualRoughness,float NdotV)
{
	//Karis  - Lazarov
	const float4 c0=float4(-1.0, -0.0275, -0.572,  0.022);
	const float4 c1=float4(1.0,  0.0425,  1.040, -0.040);

	float4 r=perceptualRoughness*c0+c1;

	float a004=min(r.x*r.x,exp2(-9.28*NdotV))*r.x+r.y;

	return float2(-1.04,1.04)*a004+r.zw;
	//Zioma - Karis
	// return float2(1.0,pow(1.0-max(perceptualRoughness,NdotV),3.0));
}

float3 specualrDFG(const PixelParams pixel)
{
#if defined(SHADING_MODEL_CLOTH)
    return pixel.F0 * pixel.DFG.z;
#else
    return lerp(pixel.DFG.yyy, pixel.DFG.xxx, pixel.F0);
#endif
}

float3 getSpecularDominantDirection(const float3 n, const float3 r, float roughness) {
    return lerp(r, n, roughness * roughness);
}

float3 getReflectedVector(const PixelParams pixel, const float3 n,const float3 view,const float3 reflected) {
#if defined(ANISOTROPY)
	//[McAuley15] ÍäÇú·´ÉäÏòÁ¿
    float3 r = getReflectedVector(pixel,view,n);
#else
    float3 r = reflected;
#endif
    return getSpecularDominantDirection(n, r, pixel.roughness);
}

float3 boxProjection (
	float3 direction, float3 position,
	float4 cubemapPosition, float3 boxMin, float3 boxMax
) {
	#if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

UnityIndirect createIndirectLight (
	Interpolators i,ShadingParameters shadingParameters,MaterialInputs material
) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	float3 viewDir=shadingParameters.viewDir;
	
// Indirect Diffuse - UnityGI_Base
	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		#if defined(LIGHTMAP_ON)
			indirectLight.diffuse =
				DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
			
			#if defined(DIRLIGHTMAP_COMBINED)
				float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
					unity_LightmapInd, unity_Lightmap, i.lightmapUV
				);
				indirectLight.diffuse = DecodeDirectionalLightmap(
					indirectLight.diffuse, lightmapDirection, i.normal
				);
			#endif

			ApplySubtractiveLighting(i, indirectLight);
		#endif

		#if defined(DYNAMICLIGHTMAP_ON)
			float3 dynamicLightDiffuse = DecodeRealtimeLightmap(
				UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, i.dynamicLightmapUV)
			);

			#if defined(DIRLIGHTMAP_COMBINED)
				float4 dynamicLightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
					unity_DynamicDirectionality, unity_DynamicLightmap,
					i.dynamicLightmapUV
				);
            	indirectLight.diffuse += DecodeDirectionalLightmap(
            		dynamicLightDiffuse, dynamicLightmapDirection, i.normal
            	);
			#else
				indirectLight.diffuse += dynamicLightDiffuse;
			#endif
		#endif

		#if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1) {
					indirectLight.diffuse = SHEvalLinearL0L1_SampleProbeVolume(
						float4(i.normal, 1), i.worldPos
					);
					indirectLight.diffuse = max(0, indirectLight.diffuse);
					#if defined(UNITY_COLORSPACE_GAMMA)
			            indirectLight.diffuse =
			            	LinearToGammaSpace(indirectLight.diffuse);
			        #endif
				}
				else {
					indirectLight.diffuse +=
						max(0, ShadeSH9(float4(i.normal, 1)));
				}
			#else
				indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
			#endif
		#endif
	
		indirectLight.diffuse *= material.ambientOcclusion;
	
 // Indirect Specular - UnityGI_IndirectSpecular
		float3 reflectionDir = reflect(-viewDir, i.normal);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = material.roughness;
		envData.reflUVW = boxProjection(
			reflectionDir, i.worldPos.xyz,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		);
		envData.reflUVW = boxProjection(
			reflectionDir, i.worldPos.xyz,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				float3 probe1 = Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
					unity_SpecCube0_HDR, envData
				);
				indirectLight.specular = lerp(probe1, probe0, interpolator);
			}
			else {
				indirectLight.specular = probe0;
			}
		#else
			indirectLight.specular = probe0;
		#endif

		indirectLight.specular *= material.ambientOcclusion;

		#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			indirectLight.specular = 0;
		#endif
	#endif

	return indirectLight;
}

// #include "UnityShaderVariables.cginc"
    // // SH lighting environment
    // half4 unity_SHAr;
    // half4 unity_SHAg;
    // half4 unity_SHAb;
    // half4 unity_SHBr;
    // half4 unity_SHBg;
    // half4 unity_SHBb;
    // half4 unity_SHC;

// float3 IrradianceSH(float3 normal)
// {
// 	
// }

//Indirect Diffuse - UnityGI_Base   NO Lightmap
float3 diffuseIrradiance(const float3 diffuseNormal,const ShadingParameters shadingParameters)
{
	float3 Fd=0.0;

	#if defined(VERTEXLIGHT_ON)
		Fd = shadingParameters.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1) {
					Fd = SHEvalLinearL0L1_SampleProbeVolume(
						float4(diffuseNormal, 1), shadingParameters.positionWS
					);
					Fd = max(0, Fd);
					#if defined(UNITY_COLORSPACE_GAMMA)
			            Fd =LinearToGammaSpace(Fd);
			        #endif
				}
				else {
					Fd +=max(0, ShadeSH9(float4(diffuseNormal, 1)));
				}
			#else
				Fd += max(0, ShadeSH9(float4(diffuseNormal, 1)));
			#endif
	#endif

	return Fd;
}

//Indirect Specular-LD Term   UnityGI_IndirectSpecular  GI.specular
float3 prefilteredRadiance(float3 reflectionDir,float roughness,float3 positionWS){
	float3 Fr=0.0;
	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		Unity_GlossyEnvironmentData envData;
		envData.roughness = roughness;
		envData.reflUVW = boxProjection(
			reflectionDir, positionWS.xyz,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
	
		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		);
		envData.reflUVW = boxProjection(
			reflectionDir, positionWS.xyz,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				float3 probe1 = Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
					unity_SpecCube0_HDR, envData
				);
				Fr = lerp(probe1, probe0, interpolator);
			}
			else {
				Fr = probe0;
			}
		#else
			Fr = probe0;
		#endif
	
		#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			Fr = 0;
		#endif
	#endif

	return Fr;
}


void evaluateClothIndirectDiffuseBRDF(const PixelParams pixel,inout float diffuse,const float NdotV)
{
#if defined(SHADING_MODEL_CLOTH)
#if defined(SUBSURFACE_COLOR)
    // Simulate subsurface scattering with a wrap diffuse term
    diffuse *= Fd_Wrap(NdotV, 0.5);
#endif
#endif
}

void evaluateSheenIBL(const PixelParams pixel,float diffuseAO,/*const in SSAO,*/
					inout float3 Fd,inout float3 Fr,const ShadingParameters shadingparameters)
{
#if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
#if defined(SHEEN_COLOR)
    // Albedo scaling of the base layer before we layer sheen on top
    Fd *= pixel.sheenScaling;
    Fr *= pixel.sheenScaling;

    float3 reflectance = pixel.sheenDFG * pixel.sheenColor;
    //reflectance *= specularAO(shading_NoV, diffuseAO, pixel.sheenRoughness, cache);
	
    Fr += reflectance * prefilteredRadiance(shadingparameters.reflected, pixel.sheenPerceptualRoughness,shadingparameters.positionWS);
#endif
#endif
}

void evaluateClearCoatIBL(const PixelParams pixel, float diffuseAO,
        /*const in SSAOInterpolationCache cache,*/ inout float3 Fd, inout float3 Fr,
		const ShadingParameters shadingParameters) {
// #if IBL_INTEGRATION == IBL_INTEGRATION_IMPORTANCE_SAMPLING
//     float specularAO = specularAO(shading_NoV, diffuseAO, pixel.clearCoatRoughness, cache);
//     isEvaluateClearCoatIBL(pixel, specularAO, Fd, Fr);
//     return;
// #endif

#if defined(CLEAR_COAT)
#if defined(_NORMAL_MAP) || defined(CLEAR_COAT_NORMAL)
    // We want to use the geometric normal for the clear coat layer
	float3 clearCoatNormal=shadingParameters.clearCoatNormalWS;
	float3 viewDir=shadingParameters.viewDir;
	
    float clearCoatNoV = max(dot(clearCoatNormal, viewDir),MIN_N_DOT_V);
    float3 clearCoatR = reflect(-viewDir, clearCoatNormal);
#else
    float clearCoatNoV = shadingParameters.NdotV;
    float3 clearCoatR = shadingParameters.reflected;
#endif
    // The clear coat layer assumes an IOR of 1.5 (4% reflectance)
    float Fc = F_Schlick(clearCoatNoV,0.04, 1.0) * pixel.clearCoat;
    float attenuation = 1.0 - Fc;
    Fd *= attenuation;
    Fr *= attenuation;

    // TODO: Should we apply specularAO to the attenuation as well?
    // float specularAO = specularAO(clearCoatNoV, diffuseAO, pixel.clearCoatRoughness, cache);
    Fr += prefilteredRadiance(clearCoatR, pixel.clearCoatPerceptualRoughness,shadingParameters.positionWS) * (/*specularAO * */Fc);
#endif
}

// void evaluateSubsurfaceIBL(const PixelParams pixel, const float3 diffuseIrradiance,
//         inout float3 Fd, inout float3 Fr,const ShadingParameters shadingparameters) {
// #if defined(SHADING_MODEL_SUBSURFACE)
//     float3 viewIndependent = diffuseIrradiance;
//     float3 viewDependent = prefilteredRadiance(-shadingParameters.viewDir, pixel.roughness, 1.0 + pixel.thickness);
//     float attenuation = (1.0 - pixel.thickness) / (2.0 * PI);
//     Fd += pixel.subsurfaceColor * (viewIndependent + viewDependent) * attenuation;
// #elif defined(SHADING_MODEL_CLOTH) && defined(SUBSURFACE_COLOR)
//     Fd *= saturate(pixel.subsurfaceColor + shadingParameters.NdotV);
// #endif
// }

void evaluateIBL(const MaterialInputs material,const PixelParams pixel,const ShadingParameters shadingparameters,inout float4 color)
{
	float NdotV=shadingparameters.NdotV;
	
	float3 Fr=float3(0.0,0.0,0.0);
	//SSAO
//TODO
// 	SSAOInterpolationCache interpolationCache;
// #if defined(BLEND_MODE_OPAQUE) || defined(BLEND_MODE_MASKED) || defined(MATERIAL_HAS_REFLECTIONS)
//     interpolationCache.uv = uvToRenderTargetUV(getNormalizedViewportCoord().xy);
// #endif

	//SSR
// #if defined(MATERIAL_HAS_REFLECTIONS)
//     vec4 ssrFr = vec4(0.0f);
// #if defined(BLEND_MODE_OPAQUE) || defined(BLEND_MODE_MASKED)
//     // do the uniform based test first
//     if (frameUniforms.ssrDistance > 0.0f) {
//         // There is no point doing SSR for very high roughness because we're limited by the fov
//         // of the screen, in addition it doesn't really add much to the final image.
//         // TODO: maybe make this a parameter
//         const float maxPerceptualRoughness = sqrt(0.5);
//         if (pixel.perceptualRoughness < maxPerceptualRoughness) {
//             // distance to camera plane
//             const float invLog2sqrt5 = 0.8614;
//             float d = -mulMat4x4Float3(getViewFromWorldMatrix(), getWorldPosition()).z;
//             float lod = max(0.0, (log2(pixel.roughness / d) + frameUniforms.refractionLodOffset) * invLog2sqrt5);
// #if !defined(MATERIAL_HAS_REFRACTION)
//             // this is temporary, until we can access the SSR buffer when we have refraction
//             ssrFr = textureLod(light_ssr, interpolationCache.uv, lod);
// #endif
//         }
//     }
// #else // BLEND_MODE_OPAQUE
//     // TODO: for blended transparency, we have to ray-march here (limited to mirror reflections)
// #endif
// #else // MATERIAL_HAS_REFLECTIONS
     // const float4 ssrFr = float4(0.0,0.0,0.0,0.0);
// #endif
// 	

// #if IBL_INTEGRATION == IBL_INTEGRATION_PREFILTERED_CUBEMAP
     // float3 E = specualrDFG(pixel);
     // if (ssrFr.a < 1.0f) { // prevent reading the IBL if possible
      //   float3 r = getReflectedVector(pixel, shadingparameters.normalWS,shadingparameters.viewDir,shadingparameters.reflected);
     	// Fr = E*prefilteredRadiance(r, pixel.roughness,shadingparameters.positionWS);
	// }
// #elif IBL_INTEGRATION == IBL_INTEGRATION_IMPORTANCE_SAMPLING
     // float3 E = float3(0.0,0.0,0.0); // TODO: fix for importance sampling
     // if (ssrFr.a < 1.0f) { // prevent evaluating the IBL if possible
     //     Fr = isEvaluateSpecularIBL(pixel, shading_normal, shading_view, shading_NoV);
     // }
// #endif

     float3 specularColor = specualrDFG(pixel);
     float3 r = getReflectedVector(pixel, shadingparameters.normalWS,shadingparameters.viewDir,shadingparameters.reflected);
     Fr = specularColor*prefilteredRadiance(r, pixel.roughness,shadingparameters.positionWS);

	

	// Ambient occlusion
	//float ssao = evaluateSSAO(interpolationCache);
    // float diffuseAO = min(material.ambientOcclusion, ssao);
	//Not Support for SSAO
    float diffuseAO = material.ambientOcclusion;
    float specularAO = SpecualrAO(NdotV, diffuseAO, pixel.roughness/*, interpolationCache*/);
 
	 float3 specularSingleBounceAO = singleBounceAO(specularAO) * pixel.energyCompensation;
	 Fr *= specularSingleBounceAO;

// #if defined(MATERIAL_HAS_REFLECTIONS)
//     ssrFr.rgb *= specularSingleBounceAO;
// #endif

	// diffuse layer
	float diffuseBRDF = singleBounceAO(diffuseAO); // Fd_Lambert() is baked in the SH below

	evaluateClothIndirectDiffuseBRDF(pixel, diffuseBRDF,NdotV);

// #if defined(MATERIAL_HAS_BENT_NORMAL)
//     vec3 diffuseNormal = shading_bentNormal;
// #else
    float3 diffuseNormal = shadingparameters.normalWS;
// #endif

// #if IBL_INTEGRATION == IBL_INTEGRATION_PREFILTERED_CUBEMAP
    // float3 diffuseIrradiance = diffuseIrradiance(diffuseNormal);
    float3 diffIrradiance = diffuseIrradiance(diffuseNormal,shadingparameters);
// #elif IBL_INTEGRATION == IBL_INTEGRATION_IMPORTANCE_SAMPLING
//     vec3 diffuseIrradiance = isEvaluateDiffuseIBL(pixel, diffuseNormal, shading_view);
// #endif

	
	float3 Fd=pixel.diffColor*diffIrradiance*diffuseBRDF;//*(1.0-E);

	// subsurface layer
	 // evaluateSubsurfaceIBL(pixel, diffuseIrradiance, Fd, Fr);
	
	// extra ambient occlusion term for the base and subsurface layers
	 multiBounceAO(diffuseAO, pixel.diffColor, Fd);
	multiBounceSpecularAO(specularAO, pixel.F0, Fr);

	// sheen layer
    evaluateSheenIBL(pixel, diffuseAO/*, interpolationCache*/, Fd,Fr,shadingparameters);
 
    // clear coat layer
    evaluateClearCoatIBL(pixel, diffuseAO/*, interpolationCache*/,Fd, Fr,shadingparameters);

// #if defined(MATERIAL_HAS_REFRACTION)
//     vec3 Ft = evaluateRefraction(pixel, shading_normal, E);
//     Ft *= pixel.transmission;
//     Fd *= (1.0 - pixel.transmission);
// #endif
//
// #if defined(MATERIAL_HAS_REFLECTIONS)
//     Fr = Fr * (1.0 - ssrFr.a) + (E * ssrFr.rgb);
// #endif

    color.rgb += Fd+Fr;

// #if defined(MATERIAL_HAS_REFRACTION)
//     color.rgb += Ft;
// #endif
}

#endif
