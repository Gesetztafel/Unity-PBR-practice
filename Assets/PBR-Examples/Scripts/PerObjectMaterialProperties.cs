using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    private static int
        baseColorId = Shader.PropertyToID("_Color"),
        cutoffId = Shader.PropertyToID("_Cutoff"),
        metallicId = Shader.PropertyToID("_Metallic"),
        //smoothnessId = Shader.PropertyToID("_Smoothness"),
        roughnessId = Shader.PropertyToID("_Roughness"),
        reflectanceId = Shader.PropertyToID("_Reflectance"),
        ClearCoatId = Shader.PropertyToID("_ClearCoat"),
        ClearCoatRoughnessId = Shader.PropertyToID("_ClearCoatRoughness"),
        AnisotropyId = Shader.PropertyToID("_Anisotropy"),
        SheenColorId = Shader.PropertyToID("_SheenColor"),
        SheenRoughnessId = Shader.PropertyToID("_SheenRoughness"),
        emissionColorId = Shader.PropertyToID("_EmissionColor");

    private static MaterialPropertyBlock block;

    [SerializeField]
    Color baseColor = Color.white;

    [SerializeField, Range(0f, 1f)]
    private float
        cutoff = 0.5f,
        metallic = 0f,
        reflectance = 0.5f,
        roughness = 0.5f,
        clearcoat = 0.0f,
        clearcoatroughness = 0.1f,
        sheenroughness = 0.1f;
    [SerializeField, Range(-1f, 1f)]
    private float
        anisotropy = 0.0f;

    [SerializeField]
    Color sheenColor = Color.white;

    [SerializeField, ColorUsage(false, true)]
    Color emissionColor = Color.black;


    private void Awake()
    {
        OnValidate();
    }

    private void OnValidate()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }

        block.SetColor(baseColorId, baseColor);
        block.SetFloat(cutoffId, cutoff);
        block.SetFloat(metallicId, metallic);
        block.SetFloat(roughnessId, roughness);
        block.SetFloat(reflectanceId, reflectance);
        block.SetFloat(ClearCoatId, clearcoat);
        block.SetFloat(ClearCoatRoughnessId, clearcoatroughness);
        block.SetFloat(AnisotropyId, anisotropy);
        block.SetFloat(SheenRoughnessId, sheenroughness);
        block.SetColor(SheenColorId, sheenColor);
        block.SetColor(emissionColorId, emissionColor);
        GetComponent<Renderer>().SetPropertyBlock(block);
    }
}
