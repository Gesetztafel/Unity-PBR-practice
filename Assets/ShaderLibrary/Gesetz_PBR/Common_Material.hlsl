#ifndef GESETZ_COMMON_MATERIAL_INCLUDED
#define GESETZ_COMMON_MATERIAL_INCLUDED

float3 computeDiffuseColor(const float4 baseColor, float metallic) {
    return baseColor.rgb * (1.0 - metallic);
}

float3 computeF0(const float4 baseColor, float metallic, float reflectance) {
    return baseColor.rgb * metallic + (reflectance * (1.0 - metallic));
}

float computeDielectricF0(float reflectance) {
    return 0.16 * reflectance * reflectance;
}

float computeMetallicFromSpecularColor(const float3 specularColor) {
    return max(max(specularColor.x,specularColor.y),specularColor.z);
}

float computeRoughnessFromGlossiness(float glossiness) {
    return 1.0 - glossiness;
}

float perceptualRoughnessToRoughness(float perceptualRoughness) {
    return perceptualRoughness * perceptualRoughness;
}

float roughnessToPerceptualRoughness(float roughness) {
    return sqrt(roughness);
}

float iorToF0(float transmittedIor, float incidentIor) {
    return ((transmittedIor - incidentIor) / (transmittedIor + incidentIor)*(transmittedIor - incidentIor) / (transmittedIor + incidentIor));
}

float f0ToIor(float f0) {
    float r = sqrt(f0);
    return (1.0 + r) / (1.0 - r);
}

float3 f0ClearCoatToSurface(const float3 f0) {
    // Approximation of iorTof0(f0ToIor(f0), 1.5)
    // This assumes that the clear coat layer has an IOR of 1.5
    return saturate(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998);
}
#endif