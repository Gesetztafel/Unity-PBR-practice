Shader "Gesetz/Shading_Model_Standard" {

	Properties {
		_MainTex ("Albedo", 2D) = "white" {}
		_Color ("Tint", Color) = (1, 1, 1, 1)

		[NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1

		//0 || 1
		//Unity r - Metallic a - Smoothness
		[NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		
		[NoScaleOffset] _RoughnessMap("Roughness Map",2D)="white"{}
		_Roughness ("Roughness", Range(0, 1)) = 0.95
		
		//仅电介质  0.5->F0 0.04  --UE Specular >0.35
		_Reflectance("Reflectance",Range(0, 1))=0.5

		[NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1

		[NoScaleOffset] _ParallaxMap ("Parallax", 2D) = "black" {}
		_ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0

		[NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)

		[NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}
		_DetailTex ("Detail Albedo", 2D) = "gray" {}
		[NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1

		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5

		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1
		
		//Anisotropic
		//[-1,1] 当此值为正时, 各向异性位于切线方向, 负值则沿副切线方向.
		_Anisotropy ("Anisotropy", Range(-1, 1)) = 0.0
		//线性RGB, 编码切线空间中的方向向量
		[NoScaleOffset] _AnisotropyDirection ("Anisotropy Direction", 2D) = "bump" {}
		
		//ClearCoat
		//0||1
		_ClearCoat ("ClearCoat", Range(0, 1)) = 0.0
		//Remapping [0,0.6]
		_ClearCoatRoughness ("ClearCoatRoughness",Range(0,1))=0.1
		[NoScaleOffset] _ClearCoatNormal ("ClearCoat Normal", 2D) = "bump" {}
		
		//PBR LUT 
		//标准模型 使用近似方法
		//[HideInInspector]_DFG("DFG_LUT",2D)="white" {}
	}

	CGINCLUDE

	#define BINORMAL_PER_FRAGMENT
	#define FOG_DISTANCE

	#define PARALLAX_BIAS 0
//	#define PARALLAX_OFFSET_LIMITING
	#define PARALLAX_RAYMARCHING_STEPS 10
	#define PARALLAX_RAYMARCHING_INTERPOLATE
//	#define PARALLAX_RAYMARCHING_SEARCH_STEPS 3
	#define PARALLAX_FUNCTION ParallaxRaymarching
	#define PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING
	
	ENDCG

	SubShader {

		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ ROUGHNESS_MAP _ROUGHNESS_ALBEDO _ROUGHNESS_METALLIC

			#pragma shader_feature REFLECTANCE

			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			
			#pragma shader_feature _PARALLAX_MAP
			
			#pragma shader_feature _EMISSION_MAP
			
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			//Filament Extended
			//Anisotropic
			// #pragma shader_feature ANISOTROPY

			//ClearCoat
			// #pragma shader_feature CLEAR_COAT
			// #pragma shader_feature CLEAR_COAT_NORMAL
			

			// #pragma shader_feature GEOMETRIC_SPECULAR_AA
			
			// #pragma shader_feature BENT_NORMAL
			// #pragma shader_feature SUBSURFACE_COLOR
			
			// #pragma shader_feature _ REFRACTION
			// #pragma shader_feature _ ABSORPTION
			// #pragma shader_feature _ TRANSMISSION
			// #pragma shader_feature _ IOR
			// #pragma shader_feature _ THICKNESS

			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma instancing_options lodfade force_same_maxcount_for_gl

			#pragma vertex VertexProgram
			#pragma fragment Gesetz_FragmentProgram

			#define FORWARD_BASE_PASS

			#include "Lighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend [_SrcBlend] One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ ROUGHNESS_MAP _ROUGHNESS_ALBEDO _ROUGHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _PARALLAX_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			
			#pragma vertex VertexProgram
			#pragma fragment Gesetz_FragmentProgram

			#include "Lighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "Deferred"
			}

			CGPROGRAM

			#pragma target 3.0
			#pragma exclude_renderers nomrt

			#pragma shader_feature _ _RENDERING_CUTOUT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ ROUGHNESS_MAP _ROUGHNESS_ALBEDO _ROUGHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _PARALLAX_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma multi_compile_prepassfinal
			#pragma multi_compile_instancing
			#pragma instancing_options lodfade

			#pragma vertex VertexProgram
			#pragma fragment Gesetz_FragmentProgram

			#define DEFERRED_PASS

			#include "Lighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS
			#pragma shader_feature _ROUGHNESS_ALBEDO

			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma instancing_options lodfade force_same_maxcount_for_gl

			#pragma vertex ShadowVertexProgram
			#pragma fragment ShadowFragmentProgram

			#include "Shadows.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "Meta"
			}

			Cull Off

			CGPROGRAM

			#pragma vertex LightmappingVertexProgram
			#pragma fragment LightmappingFragmentProgram

			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ ROUGHNESS_MAP _ROUGHNESS_ALBEDO _ROUGHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP

			#include "Lightmapping.cginc"

			ENDCG
		}
	}

	CustomEditor "Gesetz_StandardShaderGUI"
}