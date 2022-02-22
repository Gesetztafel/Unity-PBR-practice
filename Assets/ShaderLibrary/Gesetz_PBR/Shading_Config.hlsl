#ifndef GESETZ_SHADING_CONFIG_INCLUDED
#define GESETZ_SHADING_CONFIG_INCLUDED

//Math
#define PI 3.14159265358979323846

//BRDF Config
// Diffuse BRDFs
#define DIFFUSE_LAMBERT             0
#define DIFFUSE_BURLEY              1
//#define DIFFUSE_RENORMLIZED_DISNEY  2
//#define DIFFUSE_GGX_SMITH           3

// Specular BRDF
// NDF
#define SPECULAR_D_GGX              0

// Anisotropic NDFs
#define SPECULAR_D_GGX_ANISOTROPIC  0

// Cloth NDFs
#define SPECULAR_D_CHARLIE          0

// Visibility functions
#define SPECULAR_V_SMITH_GGX        0
#define SPECULAR_V_SMITH_GGX_FAST   1
#define SPECULAR_V_GGX_ANISOTROPIC  2
#define SPECULAR_V_KELEMEN          3
#define SPECULAR_V_NEUBELT          4

// Fresnel functions
#define SPECULAR_F_SCHLICK          0

#define BRDF_DIFFUSE                DIFFUSE_BURLEY

#define BRDF_SPECULAR_D             SPECULAR_D_GGX
#define BRDF_SPECULAR_V             SPECULAR_V_SMITH_GGX
#define BRDF_SPECULAR_F             SPECULAR_F_SCHLICK

#define BRDF_CLEAR_COAT_D           SPECULAR_D_GGX
#define BRDF_CLEAR_COAT_V           SPECULAR_V_KELEMEN

#define BRDF_ANISOTROPIC_D          SPECULAR_D_GGX_ANISOTROPIC
#define BRDF_ANISOTROPIC_V          SPECULAR_V_GGX_ANISOTROPIC

#define BRDF_CLOTH_D                SPECULAR_D_CHARLIE
#define BRDF_CLOTH_V                SPECULAR_V_NEUBELT

//IBL Config
// Number of spherical harmonics bands (1, 2 or 3)
#define SH_BANDS           3
// IBL integration algorithm
#define IBL_INTEGRATION_PREFILTERED_CUBEMAP         0
#define IBL_INTEGRATION_IMPORTANCE_SAMPLING         1

#define IBL_INTEGRATION                             IBL_INTEGRATION_PREFILTERED_CUBEMAP

#define IBL_INTEGRATION_IMPORTANCE_SAMPLING_COUNT   64

// Common_Materials.hlsl
 // #if defined(TARGET_MOBILE)
     // min roughness such that (MIN_PERCEPTUAL_ROUGHNESS^4) > 0 in fp16 (i.e. 2^(-14/4), rounded up)
     #define MIN_PERCEPTUAL_ROUGHNESS 0.089
     #define MIN_ROUGHNESS            0.007921
 // #else
 //     #define MIN_PERCEPTUAL_ROUGHNESS 0.045
 //     #define MIN_ROUGHNESS            0.002025
 // #endif

#define MIN_N_DOT_V 1e-4


#endif