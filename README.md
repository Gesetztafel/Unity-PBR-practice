---
typora-root-url: Assets\ShaderLibrary\Gesetz_PBR\Docs\images
---

# Unity-PBR-practice

## 结果展示

### Shandard Model

![Standard](/Standard.JPG)

Dielectrics-Reflectance 1.0-0.0 Metallic 0.0 Roughness 0.0

Roughness(Metal) 1.0-0.0

Roughness(Dielectrics) 1.0-0.0

Metallic 1.0-0.0

#### Clear Coat

![ClearCoat](/ClearCoat.JPG)

CleatCoatRoughness 1.0-0.0

ClearCoat 1.0-0.0

#### Anisotropy

![Anisotropy](/Anisotropy.JPG)

Anisotropy 1.0-0.0

![Anisotropy -1.0 1.0](/Anisotropy -1.0 1.0.JPG)

Anisotropy 1.0, -1.0

#### Sheen

![Sheen](/Sheen.JPG)

#### PBR 模型展示

注：为了与Unity Standard 匹配，模型展示部分，光照模型 *PI；

![Cerberus_LP Gesetz](/Cerberus_LP Gesetz.JPG)

![monkey(left-Gesetz right-Standard)](/monkey(left-Gesetz right-Standard).JPG)

monkey left-Gesetz right-Standard

![](/monkey-back(left-Standard right-Gesetz).JPG)

monkey-back(left-Standard right-Gesetz)

![](/Rustediron-Ball.JPG)

### Cloth Model

![](Cloth left - Cloth right - Standard.JPG)

### SubSurface Model

TODO



## References

[Romain Guy&Mathias Agopian] [Physically Based Rendering in Filament](https://google.github.io/filament/)

中文翻译：[Jerkwin](https://jerkwin.github.io/filamentcn/Filament.md.html#%E6%9D%90%E8%B4%A8%E7%B3%BB%E7%BB%9F/%E9%80%8F%E6%98%8E%E6%B6%82%E5%B1%82%E6%A8%A1%E5%9E%8B)



[Walter 07]Microfacet Models for Refraction through Rough Surfaces 

[Burley12] Physically Based Shading at Disney

[Neubelt13] Crafting a Next-Gen Material Pipeline for The Order 1886

[Lazarov13] Getting More Physical in Call of Duty Black Ops II 

[Karis13 b]Real Shading in Unreal Engine 4

GDC 2014-Physically Based Shading in Unity

[Lagarde14]Moving Frostbite to Physically Based Rendering

GDC 2017-PBR Diffuse Lighting for GGX+Smith Microsurfaces



[Heitz 14 a]Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs

[Heitz 14]Understanding the Masking-Shadowing Function



[Heitz.16] Multiple-Scattering Microfacet BSDFs with the Smith Model 

[Kulla & Conty 17]Revisiting Physically Based Shading at Imageworks



[Hoffman]Physics and Math of Shading 

[Hoffman 16]Recent Advances in Physically Based Shading

[Lagarde 17]Physically-Based Materials Where Are We

### 参考博文

PBR-White-Paper —— 浅墨  毛星云 R.I.P.

知乎：

Unity PBR Standard Shader 实现详解 雨轩

Unity Standard Shader 技术分析 骥云

Unity的PBR扩展 YOung

Unity SRP下做PBR基于物理的渲染和踩坑 GuardHei

### 代码参考

Unity - Builtin - Standard

[Google Filament](github.com/google/filament)

Catlike Coding/Unity/Rendering&Advanced Rendering —简化实现 Unity- Builtin Standard
