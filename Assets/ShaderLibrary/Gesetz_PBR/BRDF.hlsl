#ifndef GESETZ_BRDF_INCLUDED
#define GESETZ_BRDF_INCLUDED

#include "Shading_Config.hlsl"

#define PI 3.14159265358979323846

#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

//BRDF
//specular BRDF

//D NDF GGX
//[Walter et al. 07]
float D_GGX(float NdotH,float roughness,const float3 H){
//fp16 optimize
//#if defined (TARGET_MOBILE)
//	float3 NxH=cross(N,H);
//	float oneMinusNdotHSquared=dot(NxH,NxH);
//#else
	float oneMinusNdotHSquared=1.0-NdotH*NdotH; 
//#endif
	float a =NdotH*roughness;
	float k = roughness / (oneMinusNdotHSquared + a * a);
	float d=k * k * (1.0 / PI);
	
	return saturateMediump(d);
}

//Anisotropy
//[Burley 12]
float D_GGX_Anisotropic(float TdotH,float BdotH,float NdotH,float at, float ab) {
	float a2 = at * ab;
	float3 d = float3(ab * TdotH, at * BdotH, a2 * NdotH);
	float d2 = dot(d, d);
	float b2 = a2 / d2;
	return a2 * b2 * b2 * (1.0 / PI);
}

//Cloth
//[Ashikhmin 07]
float D_Ashikhmin(float roughness, float NdotH) {
	float a2 = roughness * roughness;
	float cos2h = NdotH * NdotH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}
//[Estevez et al. 17] "Production Friendly Microfacet Sheen BRDF"
float D_Charlie(float roughness, float NdotH) {
    float invAlpha  = 1.0 / roughness;
    float cos2h = NdotH * NdotH;
    float sin2h = max(1.0 - cos2h, 0.0078125);
	// 2^(-14/2), so sin2h^2 > 0 in fp16
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

//G [Heitz 2014b]
//Smith-GGX height-joined
float V_SmithGGXCorrelated(float NdotV,float NdotL,float roughness){
	float a2=roughness*roughness;
	
	float GGX_V=NdotL*sqrt((NdotV-a2*NdotV)*NdotV+a2);
	float GGX_L=NdotV*sqrt((NdotL-a2*NdotL)*NdotL+a2);
	float v=0.5/(GGX_V+GGX_L);

	return saturateMediump(v);
}

//Filament
//[Hammon 17]
float V_SmithGGXCorrelatedFast(float NdotV,float NdotL,float roughness){
	// float a=roughness;
	// float GGXV=NdotL*(NdotV*(1.0-a)+a);
	// float GGXL=NdotV*(NdotL*(1.0-a)+a);
	// float v=0.5/(GGXV+GGXL);
	//GLSL mix(x,y,s);
	float v=0.5/lerp(2.0*NdotL*NdotV,NdotL+NdotV,roughness);
	return saturateMediump(v);
}

//References
//UE4
// float Vis_SmithJointApprox( float a2, float NoV, float NoL )
// {
// 	float a = sqrt(a2);// a2 = Pow4( Roughness )
// 	float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
// 	float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
// 	return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
// }
//Unity HDRP
// float V_SmithJointGGX(float NdotL, float NdotV, float roughness, float partLambdaV)
// {
// 	float a2 = Sq(roughness);
// 	// Original formulation:
// 	// lambda_v = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5
// 	// lambda_l = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5
// 	// G = 1 / (1 + lambda_v + lambda_l);
// 	// Reorder code to be more optimal:
// 	float lambdaV = NdotL * partLambdaV;
// 	float lambdaL = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);
// 	// Simplify visibility term: (2.0 * NdotL * NdotV) / ((4.0 * NdotL * NdotV)* (lambda_v + lambda_l))
// 	return 0.5 / (lambdaV + lambdaL);
// }
// float V_SmithJointGGX(float NdotL, float NdotV, float roughness)
// {
// 	float partLambdaV = GetSmithJointGGXPartLambdaV(NdotV, roughness);
// 	return V_SmithJointGGX(NdotL, NdotV, roughness, partLambdaV);
// }
// float GetSmithJointGGXPartLambdaVApprox(float NdotV, float roughness)
// {
// 	float a = roughness;
// 	return NdotV * (1 - a) + a;
// }

//Anisotropy
//[Heitz 14]
float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float TdotV, float BdotV,
        float TdotL, float BdotL, float NdotV, float NdotL) {
    float lambdaV = NdotL * length(float3(at * TdotV, ab * BdotV, NdotV));
    float lambdaL = NdotV * length(float3(at * TdotL, ab * BdotL, NdotL));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturateMediump(v);
}

//ClearCoat
//[Kelemen 01]
float V_Kelemen(float LdotH){
	return 0.25 / (LdotH * LdotH);
}
//[Neubelt 13]
float V_Neubelt(float NdotV,float NdotL)
{
	return saturateMediump(1.0/(4.0*(NdotL+NdotV-NdotL*NdotV)));
}

float Pow5(float x){
	float x_2=x*x;
	return x_2*x_2*x;
}
// F Fresnel
//[Schlick 94]
float3 F_Schlick(float VdotH,const float3 F0,float3 F90){
	return F0+(F90-F0)*Pow5(1.0-VdotH);
}
float3 F_Schlick(float VdotH,const float3 F0){
	float F=Pow5(1.0-VdotH);
	return F+F0*(1.0-F);
}
float F_Schlick(float VdotH,float F0,float F90){
	return F0+(F90-F0)*Pow5(1.0-VdotH);
}
//Diffuse BRDF
//Lambert
float Fd_Lambert() {
	return 1.0/PI;
}
//[Burley12] Disney Diffuse
float Fd_Burley(float NdotV,float NdotL,float LdotH,float roughness){
	float F90=0.5+2.0*roughness*LdotH*LdotH;

	float L_Scatter=F_Schlick(NdotL,1.0,F90);
	float V_Scatter=F_Schlick(NdotV,1.0,F90);

	return L_Scatter*V_Scatter*(1.0/PI);
}

//Frostbite [Lagarde 14] renormalized Disney Diffuse
float Fd_Renormalized_Disney (float NdotV,float NdotL,float LdotH,float linearRoughness){
	float energyBias=lerp(0,0.5,linearRoughness);
	float energyFactor=lerp(1.0,1.0/1.51,linearRoughness);

	float F90=energyBias+2.0*linearRoughness*LdotH*LdotH;
	float3 F0=float3(1.0f,1.0f,1.0f);
	
	float L_Scatter=F_Schlick(NdotL,F0,F90).r;
	float V_Scatter=F_Schlick(NdotV,F0,F90).r;

	return L_Scatter*V_Scatter*energyFactor;
}

// [Hammon 17] GGX+Diffuse
// 𝑓𝑎𝑐𝑖𝑛𝑔=0.5+0.5 𝐿⋅𝑉
// 𝑟𝑜𝑢𝑔ℎ=𝑓𝑎𝑐𝑖𝑛𝑔 (0.9−0.4𝑓𝑎𝑐𝑖𝑛𝑔) (\frac{0.5+𝑁⋅𝐻}{𝑁⋅𝐻})
// 𝑠𝑚𝑜𝑜𝑡ℎ=1.05 (1− (1−𝑁⋅𝐿) ^5) (1− (1−𝑁⋅𝑉 )^5)
// 𝑠𝑖𝑛𝑔𝑙𝑒= 1/𝜋 𝑙𝑒𝑟𝑝(smooth,rough,𝛼)
// 𝑚𝑢𝑙𝑡𝑖 =0.1159𝛼
// 𝑑𝑖𝑓𝑓𝑢𝑠𝑒=𝑎𝑙𝑏𝑒𝑑𝑜∗ (𝑠𝑖𝑛𝑔𝑙𝑒+𝑎𝑙𝑏𝑒𝑑𝑜∗𝑚𝑢𝑙𝑡𝑖)
// float Fd_GGX_Diffuse(float LdotV)
// {
//
// }

float Fd_Wrap(float NdotL,float w)
{
	return saturate((NdotL+w)/sqrt(1.0+w));
}

//Dispatches
float Distribution(float roughness,float NdotH,const float3 H)
{
#if BRDF_SPECULAR_D == SPECULAR_D_GGX
    return D_GGX(NdotH,roughness,H);
#endif
}
float Visibility(float roughness, float NdotV, float NdotL) {
#if BRDF_SPECULAR_V == SPECULAR_V_SMITH_GGX
    return V_SmithGGXCorrelated(NdotV,NdotL,roughness);
#elif BRDF_SPECULAR_V == SPECULAR_V_SMITH_GGX_FAST
    return V_SmithGGXCorrelated_Fast(NdotV,NdotL,roughness);
#endif
}
float3 Fresnel(const float3 f0, float LdotH) {
#if BRDF_SPECULAR_F == SPECULAR_F_SCHLICK
    float3 f90 = saturate(dot(f0, float3(50.0 * 0.33,50.0 * 0.33,50.0 * 0.33)));
    return F_Schlick(LdotH,f0, f90 );
#endif
}

float Distribution_Anisotropic(float at, float ab, 
				float TdotH, float BdotH, float NdotH) {
#if BRDF_ANISOTROPIC_D == SPECULAR_D_GGX_ANISOTROPIC
    return D_GGX_Anisotropic(TdotH,BdotH,NdotH,at,ab);
#endif
}

float Visibility_Anisotropic(float roughness, float at, float ab,
        float TdotV, float BdotV, float TdotL, float BdotL, float NdotV, float NdotL) {
#if BRDF_ANISOTROPIC_V == SPECULAR_V_SMITH_GGX
    return V_SmithGGXCorrelated(NdotV, NdotL,roughness);
#elif BRDF_ANISOTROPIC_V == SPECULAR_V_GGX_ANISOTROPIC
    return V_SmithGGXCorrelated_Anisotropic(at,ab,TdotV, BdotV,
        TdotL, BdotL, NdotV, NdotL);
#endif
}

float Distribution_ClearCoat(float roughness, float NdotH, const float3 H) {
#if BRDF_CLEAR_COAT_D == SPECULAR_D_GGX
    return D_GGX(NdotH,roughness,H);
#endif
}

float Visibility_ClearCoat(float LdotH) {
#if BRDF_CLEAR_COAT_V == SPECULAR_V_KELEMEN
    return V_Kelemen(LdotH);
#endif
}

float Distribution_Cloth(float roughness, float NdotH) {
#if BRDF_CLOTH_D == SPECULAR_D_CHARLIE
    return D_Charlie(roughness,NdotH);
#endif
}

float Visibility_Cloth(float NdotV, float NdotL) {
#if BRDF_CLOTH_V == SPECULAR_V_NEUBELT
    return V_Neubelt(NdotV,NdotL);
#endif
}

float Diffuse(float roughness, float NdotV, float NdotL, float LdotH) {
#if BRDF_DIFFUSE == DIFFUSE_LAMBERT
    return Fd_Lambert();
#elif BRDF_DIFFUSE == DIFFUSE_BURLEY
    return Fd_Burley(NdotV, NdotL, LdotH,roughness);
#endif
}
#endif