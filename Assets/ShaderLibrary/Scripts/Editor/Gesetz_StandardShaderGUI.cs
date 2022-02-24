using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class Gesetz_StandardShaderGUI : ShaderGUI
{

    enum RoughnessSource
    {
        Uniform, RoughnessMap, Albedo, Metallic
    }

    enum RenderingMode
    {
        Opaque, Cutout, Fade, Transparent
    }

    struct RenderingSettings
    {
        public RenderQueue queue;
        public string renderType;
        public BlendMode srcBlend, dstBlend;
        public bool zWrite;

        public static RenderingSettings[] modes = {
            new RenderingSettings() {
                queue = RenderQueue.Geometry,
                renderType = "",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings() {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.SrcAlpha,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            },
            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            }
        };
    }

    static GUIContent staticLabel = new GUIContent();

    static ColorPickerHDRConfig emissionConfig =
        new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;
    bool shouldShowAlphaCutoff;

    public override void OnGUI(
        MaterialEditor editor, MaterialProperty[] properties
    )
    {
        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;

        DoRenderingMode();

        DoMain();
        DoSecondary();

        DoAnisotropy();
        DoClearCoat();
        DoSheen();

        DoAdvanced();

        DoSpecularAA();

        DoLUT();
        DoLUT_CLOTH();
    }

    void DoRenderingMode()
    {
        RenderingMode mode = RenderingMode.Opaque;
        shouldShowAlphaCutoff = false;
        if (IsKeywordEnabled("_RENDERING_CUTOUT"))
        {
            mode = RenderingMode.Cutout;
            shouldShowAlphaCutoff = true;
        }
        else if (IsKeywordEnabled("_RENDERING_FADE"))
        {
            mode = RenderingMode.Fade;
        }
        else if (IsKeywordEnabled("_RENDERING_TRANSPARENT"))
        {
            mode = RenderingMode.Transparent;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(
            MakeLabel("Rendering Mode"), mode
        );
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
            SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
            SetKeyword(
                "_RENDERING_TRANSPARENT", mode == RenderingMode.Transparent
            );

            RenderingSettings settings = RenderingSettings.modes[(int)mode];
            foreach (Material m in editor.targets)
            {
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
                m.SetInt("_SrcBlend", (int)settings.srcBlend);
                m.SetInt("_DstBlend", (int)settings.dstBlend);
                m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
            }
        }

        if (mode == RenderingMode.Fade || mode == RenderingMode.Transparent)
        {
            DoSemitransparentShadows();
        }
    }

    void DoSemitransparentShadows()
    {
        EditorGUI.BeginChangeCheck();
        bool semitransparentShadows =
            EditorGUILayout.Toggle(
                MakeLabel("Semitransp. Shadows", "Semitransparent Shadows"),
                IsKeywordEnabled("_SEMITRANSPARENT_SHADOWS")
            );
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_SEMITRANSPARENT_SHADOWS", semitransparentShadows);
        }
        if (!semitransparentShadows)
        {
            shouldShowAlphaCutoff = true;
        }
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(
            MakeLabel(mainTex, "Albedo (RGB)"), mainTex, FindProperty("_Color")
        );

        if (shouldShowAlphaCutoff)
        {
            DoAlphaCutoff();
        }
        DoMetallic();

        DoRoughnessMap();
        DoRoughness();

        DoReflectance();
        DoNormals();
        DoParallax();
        DoOcclusion();
        DoEmission();
        DoDetailMask();
        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoAlphaCutoff()
    {
        MaterialProperty slider = FindProperty("_Cutoff");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    void DoNormals()
    {
        MaterialProperty map = FindProperty("_NormalMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map), map,
            tex ? FindProperty("_BumpScale") : null
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_NORMAL_MAP", map.textureValue);
        }
    }

    void DoMetallic()
    {
        MaterialProperty map = FindProperty("_MetallicMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Metallic (R)"), map,
            tex ? null : FindProperty("_Metallic")
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_METALLIC_MAP", map.textureValue);
        }
    }


    void DoParallax()
    {
        MaterialProperty map = FindProperty("_ParallaxMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Parallax (G)"), map,
            tex ? FindProperty("_ParallaxStrength") : null
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_PARALLAX_MAP", map.textureValue);
        }
    }

    void DoOcclusion()
    {
        MaterialProperty map = FindProperty("_OcclusionMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Occlusion (G)"), map,
            tex ? FindProperty("_OcclusionStrength") : null
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_OCCLUSION_MAP", map.textureValue);
        }
    }

    void DoEmission()
    {
        MaterialProperty map = FindProperty("_EmissionMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(
            MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"),
            emissionConfig, false
        );
        editor.LightmapEmissionProperty(2);
        if (EditorGUI.EndChangeCheck())
        {
            if (tex != map.textureValue)
            {
                SetKeyword("_EMISSION_MAP", map.textureValue);
            }

            foreach (Material m in editor.targets)
            {
                m.globalIlluminationFlags &=
                    ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }
    }

    void DoDetailMask()
    {
        MaterialProperty mask = FindProperty("_DetailMask");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(mask, "Detail Mask (A)"), mask
        );
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_DETAIL_MASK", mask.textureValue);
        }
    }

    void DoSecondary()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(detailTex, "Albedo (RGB) multiplied by 2"), detailTex
        );
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }
        DoSecondaryNormals();
        editor.TextureScaleOffsetProperty(detailTex);
    }

    void DoSecondaryNormals()
    {
        MaterialProperty map = FindProperty("_DetailNormalMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map), map,
            tex ? FindProperty("_DetailBumpScale") : null
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
        }
    }

    void DoAdvanced()
    {
        GUILayout.Label("Advanced Options", EditorStyles.boldLabel);

        editor.EnableInstancingField();
    }

    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    static GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(
        MaterialProperty property, string tooltip = null
    )
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword(string keyword, bool state)
    {
        if (state)
        {
            foreach (Material m in editor.targets)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material m in editor.targets)
            {
                m.DisableKeyword(keyword);
            }
        }
    }

    bool IsKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    void RecordAction(string label)
    {
        editor.RegisterPropertyChangeUndo(label);
    }

    void DoRoughnessMap()
    {
        MaterialProperty map = FindProperty("_RoughnessMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Roughness"), map,
            tex ? null : FindProperty("_Roughness")
            );

        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("ROUGHNESS_MAP", map.textureValue);
        }
    }

    void DoRoughness()
    {
        RoughnessSource source = RoughnessSource.Uniform;

        if (IsKeywordEnabled("ROUGHNESS_MAP"))
        {
            source = RoughnessSource.RoughnessMap;
        }
        else if (IsKeywordEnabled("_ROUGHNESS_ALBEDO"))
        {
            source = RoughnessSource.Albedo;
        }
        else if (IsKeywordEnabled("_ROUGHNESS_METALLIC"))
        {
            source = RoughnessSource.Metallic;
        }

        EditorGUI.BeginChangeCheck();
        source = (RoughnessSource)EditorGUILayout.EnumPopup(
            MakeLabel("Source"), source
        );
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Roughness Source");
            SetKeyword("ROUGHNESS_MAP", source == RoughnessSource.RoughnessMap);
            SetKeyword("_ROUGHNESS_ALBEDO", source == RoughnessSource.Albedo);
            SetKeyword(
                "_ROUGHNESS_METALLIC", source == RoughnessSource.Metallic
            );
        }
    }

    void DoReflectance()
    {
        MaterialProperty slider = FindProperty("_Reflectance");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel += 1;
        EditorGUI.indentLevel -= 3;
    }

    void DoLUT()
    {
        MaterialProperty map = FindProperty("_DFG");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "DFG LUT"), map
        );
    }

    void DoLUT_CLOTH()
    {
        MaterialProperty map = FindProperty("_DFG_CLOTH");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "DFG LUT CLOTH"), map
        );
    }

    void DoAnisotropy()
    {
        bool isAnisotropy = Array.IndexOf(target.shaderKeywords, "ANISOTROPY") != -1;

        EditorGUI.BeginChangeCheck();
        isAnisotropy = EditorGUILayout.Toggle("Anisotropy", isAnisotropy);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("ANISOTROPY", isAnisotropy);
        }

        if (isAnisotropy)
        {
            MaterialProperty slider = FindProperty("_Anisotropy");
            editor.ShaderProperty(slider, MakeLabel(slider));
            DoAnisotropyDirection();
        }
    }

    void DoAnisotropyDirection()
    {
        MaterialProperty map = FindProperty("_AnisotropyDirection");
        Texture tex = map.textureValue;
        editor.TexturePropertySingleLine(
            MakeLabel(map), map
        );
    }

    void DoClearCoat()
    {
        bool isClearCoat = Array.IndexOf(target.shaderKeywords, "CLEAR_COAT") != -1;

        EditorGUI.BeginChangeCheck();
        isClearCoat = EditorGUILayout.Toggle("Clear Coat", isClearCoat);

        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("CLEAR_COAT", isClearCoat);
            SetKeyword("CLEAR_COAT_ROUGHNESS", isClearCoat);
        }

        if (isClearCoat)
        {
            DoClearCoatMap();
            DoClearCoatRoughness();
            DoClearCoatNormal();
        }
    }

    void DoClearCoatMap()
    {
        MaterialProperty map = FindProperty("_ClearCoat_Map");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Clear Coat(R)"), map,
            tex ? null : FindProperty("_ClearCoat")
        );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("CLEARCOAT_MAP", map.textureValue);
        }

    }
    void DoClearCoatRoughness()
    {
        MaterialProperty slider = FindProperty("_ClearCoatRoughness");
        editor.ShaderProperty(slider, MakeLabel(slider));
    }

    void DoClearCoatNormal()
    {
        MaterialProperty map = FindProperty("_ClearCoat_NormalMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map), map);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("CLEAR_COAT_NORMAL", map.textureValue);
        }
    }

    void DoSheen()
    {
        bool isSheen = Array.IndexOf(target.shaderKeywords, "SHEEN_COLOR") != -1;
        EditorGUI.BeginChangeCheck();
        isSheen = EditorGUILayout.Toggle("Sheen", isSheen);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("SHEEN_COLOR", isSheen);
        }

        if (isSheen)
        {
            DoSheenColor();
            DoSheenRoughness();
        }
    }

    void DoSheenColor()
    {
        MaterialProperty sheenColor = FindProperty("_SheenColor");
        editor.ShaderProperty(sheenColor, MakeLabel(sheenColor));
    }
    void DoSheenRoughness()
    {
        MaterialProperty slider = FindProperty("_SheenRoughness");
        editor.ShaderProperty(slider, MakeLabel(slider));
    }

    void DoSpecularAA()
    {
        bool isSpecularAA = Array.IndexOf(target.shaderKeywords, "GEOMETRIC_SPECULAR_AA") != -1;
        EditorGUI.BeginChangeCheck();
        isSpecularAA = EditorGUILayout.Toggle("Geometric Specular AA", isSpecularAA);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("GEOMETRIC_SPECULAR_AA", isSpecularAA);
        }
    }
}
