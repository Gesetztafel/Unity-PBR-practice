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
// #if defined(BENT_NORMAL)
//     float3  bentNormalWS;
// #endif

#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor;
#endif

// #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
// 	float2 lightmapUV;
// #endif
//
// #if defined(DYNAMICLIGHTMAP_ON)
// 	float2 dynamicLightmapUV;
// #endif
};
float3 createBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}
ShadingParameters GetShadingParameters(Interpolators i)
{
	ShadingParameters shadingParameters;

	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = createBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	#else
		float3 binormal = i.binormal;
	#endif
	//TBN matrix ÁÐÖ÷Ðò mul ×ó³Ë 
 	shadingParameters.tangentToWorld=float3x3(
		i.tangent.x,binormal.x,i.normal.x,
		i.tangent.y,binormal.y,i.normal.y,
		i.tangent.z,binormal.z,i.normal.z
	);
	// shadingParameters.tangentToWorld[0]=i.tangent;
	// shadingParameters.tangentToWorld[1]=binormal;
	// shadingParameters.tangentToWorld[2]=i.normal;
	//normal
	float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
	shadingParameters.normalWS=normalize(
								tangentSpaceNormal.x*i.tangent+
								tangentSpaceNormal.y * binormal +
								tangentSpaceNormal.z * i.normal
								);
#if defined(CLEAR_COAT)
    #if defined(CLEAR_COAT_NORMAL)
		float3 clearcoatNormalTS=GetClearCoatNormalTS(i);
		shadingParameters.clearCoatNormalWS=normalize(
								clearcoatNormalTS.x*i.tangent+
								clearcoatNormalTS.y * binormal +
								clearcoatNormalTS.z * i.normal
								);;
	#else
		shadingParameters.clearCoatNormalWS=shadingParameters.normalWS;
	#endif
#endif

#if defined(VERTEXLIGHT_ON)
	shadingParameters.vertexLightColor=i.vertexLightColor;
#endif

// #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
// 	shadingParameters.lightmapUV=i.lightmapUV;
// #endif
//
// #if defined(DYNAMICLIGHTMAP_ON)
// 	shadingParameters.dynamicLightmapUV=i.dynamicLightmapUV;
// #endif

	shadingParameters.positionWS=i.worldPos;
	shadingParameters.viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
	shadingParameters.geometricNormalWS=normalize(i.normal);
	shadingParameters.reflected=reflect(-shadingParameters.viewDir,shadingParameters.normalWS);
	shadingParameters.NdotV=abs(dot(shadingParameters.normalWS,shadingParameters.viewDir));
	
	return shadingParameters;
}

#endif