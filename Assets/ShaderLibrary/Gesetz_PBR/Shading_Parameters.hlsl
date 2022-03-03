#ifndef GESETZ_SHADING_PARAMETERS_INCLUDED
#define GESETZ_SHADING_PARAMETERS_INCLUDED

#include "Common_Shading.hlsl"

// /**
//  * Computes global shading parameters used to apply lighting, such as the view
//  * vector in world space, the tangent frame at the shading point, etc.
//  */
// void computeShadingParams() {
// #if defined(HAS_ATTRIBUTE_TANGENTS)
//     highp vec3 n = vertex_worldNormal;
// #if defined(MATERIAL_NEEDS_TBN)
//     highp vec3 t = vertex_worldTangent.xyz;
//     highp vec3 b = cross(n, t) * sign(vertex_worldTangent.w);
// #endif
//
// #if defined(MATERIAL_HAS_DOUBLE_SIDED_CAPABILITY)
//     if (isDoubleSided()) {
//         n = gl_FrontFacing ? n : -n;
// #if defined(MATERIAL_NEEDS_TBN)
//         t = gl_FrontFacing ? t : -t;
//         b = gl_FrontFacing ? b : -b;
// #endif
//     }
// #endif
//
//     shading_geometricNormal = normalize(n);
//
// #if defined(MATERIAL_NEEDS_TBN)
//     // We use unnormalized post-interpolation values, assuming mikktspace tangents
//     shading_tangentToWorld = mat3(t, b, n);
// #endif
// #endif
//
//     shading_position = vertex_worldPosition.xyz;
//     shading_view = normalize(frameUniforms.cameraPosition - shading_position);
//
//     // we do this so we avoid doing (matrix multiply), but we burn 4 varyings:
//     //    p = clipFromWorldMatrix * shading_position;
//     //    shading_normalizedViewportCoord = p.xy * 0.5 / p.w + 0.5
//     shading_normalizedViewportCoord = vertex_position.xy * (0.5 / vertex_position.w) + 0.5;
// }
//
// /**
//  * Computes global shading parameters that the material might need to access
//  * before lighting: N dot V, the reflected vector and the shading normal (before
//  * applying the normal map). These parameters can be useful to material authors
//  * to compute other material properties.
//  *
//  * This function must be invoked by the user's material code (guaranteed by
//  * the material compiler) after setting a value for MaterialInputs.normal.
//  */
// void prepareMaterial(const MaterialInputs material) {
// #if defined(HAS_ATTRIBUTE_TANGENTS)
// #if defined(MATERIAL_HAS_NORMAL)
//     shading_normal = normalize(shading_tangentToWorld * material.normal);
// #else
//     shading_normal = getWorldGeometricNormalVector();
// #endif
//     shading_NoV = clampNoV(dot(shading_normal, shading_view));
//     shading_reflected = reflect(-shading_view, shading_normal);
//
// #if defined(MATERIAL_HAS_BENT_NORMAL)
//     shading_bentNormal = normalize(shading_tangentToWorld * material.bentNormal);
// #endif
//
// #if defined(MATERIAL_HAS_CLEAR_COAT)
// #if defined(MATERIAL_HAS_CLEAR_COAT_NORMAL)
//     shading_clearCoatNormal = normalize(shading_tangentToWorld * material.clearCoatNormal);
// #else
//     shading_clearCoatNormal = getWorldGeometricNormalVector();
// #endif
// #endif
// #endif
// }

float3 createBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}
ShadingParameters computeShadingParams(Interpolators i)
{
	ShadingParameters shadingParameters;
	
	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = createBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	#else
		float3 binormal = i.binormal;
	#endif

	//HLSL ÁÐÖ÷Ðò mul() ×ó³Ë
 	shadingParameters.tangentToWorld=float3x3(
		i.tangent.x,binormal.x,i.normal.x,
		i.tangent.y,binormal.y,i.normal.y,
		i.tangent.z,binormal.z,i.normal.z
	);
	
	// shadingParameters.tangentToWorld[0]=i.tangent;
	// shadingParameters.tangentToWorld[1]=binormal;
	// shadingParameters.tangentToWorld[2]=i.normal;

	shadingParameters.geometricNormalWS=normalize(i.normal);
	
	shadingParameters.positionWS=i.worldPos;
	shadingParameters.viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);

#if defined(VERTEXLIGHT_ON)
	shadingParameters.vertexLightColor=i.vertexLightColor;
#endif

	float3x3 tangentToWorld=shadingParameters.tangentToWorld;

	float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
	shadingParameters.normalWS=normalize(mul(tangentToWorld,tangentSpaceNormal));
	// shadingParameters.normalWS=normalize(
	// 							tangentSpaceNormal.x*i.tangent+
	// 							tangentSpaceNormal.y * binormal +
	// 							tangentSpaceNormal.z * i.normal
	// 							);


	shadingParameters.reflected=reflect(-shadingParameters.viewDir,shadingParameters.normalWS);
	shadingParameters.NdotV=clampNdotV(dot(shadingParameters.normalWS,shadingParameters.viewDir));

#if defined(BENT_NORMAL)
	float3 clearcoatNormalTS=GetBentNormalTS(i);
    shadingParameters.bentNormal = normalize(mul(tangentToWorld,material.bentNormal));
#endif
	
#if defined(CLEAR_COAT)
    #if defined(CLEAR_COAT_NORMAL)
		float3 clearcoatNormalTS=GetClearCoatNormalTS(i);
		shadingParameters.clearCoatNormalWS=normalize(mul(tangentToWorld,clearcoatNormalTS));
		// shadingParameters.clearsCoatNormalWS=normalize(
		// 						clearcoatNormalTS.x*i.tangent+
		// 						clearcoatNormalTS.y * binormal +
		// 						clearcoatNormalTS.z * i.normal
		// 						);
	#else
		shadingParameters.clearCoatNormalWS=shadingParameters.normalWS;
	#endif
#endif

	return shadingParameters;
}

// void prepareMaterial(const MaterialInputs material,inout ShadingParameters shadingParameters)
// {
// 	float3x3 tangentToWorld=shadingParameters.tangentToWorld;
//
// #if defined(_NORMAL_MAP)
// 	float3 tangentSpaceNormal = material.normal;
// 	
// shadingParameters.normalWS=normalize(mul(tangentToWorld,tangentSpaceNormal));
//#else
// 	shadingParameters.normalWS=shadingParameters.geometricNormalWS;
// #endif
//
// 	shadingParameters.reflected=reflect(-shadingParameters.viewDir,shadingParameters.normalWS);
// 	shadingParameters.NdotV=abs(dot(shadingParameters.normalWS,shadingParameters.viewDir));
//
// #if defined(BENT_NORMAL)
//     shadingParameters.bentNormal = normalize(mul(tangentToWorld,material.bentNormal));
// #endif
// 	
// #if defined(CLEAR_COAT)
//     #if defined(CLEAR_COAT_NORMAL)
// 		float3 clearcoatNormalTS=material.clearCoatNormal;
// 		shadingParameters.clearCoatNormalWS=normalize(mul(tangentToWorld,clearcoatNormalTS));

// 	#else
// 		shadingParameters.clearCoatNormalWS=shadingParameters.normalWS;
// 	#endif
// #endif
// 	
// }

#endif
