## 标椎模型

Disney Principled BRDF  

#### **Diffuse Term:**

Lambertian Diffuse；[Burley 12] Disney Diffuse  

#### **Specular Term:**

Cook-Torrance 镜面微表面模型:

Specular D : GGX NDF +Specular G : Smith-GGX Height-Correlated Masking&Shadowing 

Specular F : Schlick Fresnel  



### Indirect Lighting

IBL(Image Based Lighting)——Light probe(光照探头)，Reflection probe(反射探头，天空盒..)

#### Indirect Diffuse:



#### Indirect Specular : 

- Pre-filtered environment map  



- Environment BRDF  

i 2D LUT  

TODO

ii 解析拟合  (USE THIS)

### 参数化



### Clear Coat



### Anisotropy



### Shader GUI

../Scripts/Editor/



## 结果展示

### Shandard Model

![](..\Docs\images\Standard.JPG)

Dielectrics-Reflectance 1.0-0.0 Metallic 0.0 Roughness 0.0

Roughness(Metal) 1.0-0.0

Roughness(Dielectrics) 1.0-0.0

Metallic 1.0-0.0

#### Clear Coat

![](..\Docs\images\ClearCoat.JPG)

CleatCoatRoughness 1.0-0.0

ClearCoat 1.0-0.0

#### Anisotropy

![](..\Docs\images\Anisotropy.JPG)

Anisotropy 1.0-0.0

![](..\Docs\images\Anisotropy -1.0 1.0.JPG)

Anisotropy 1.0, -1.0

#### Sheen

![](..\Docs\images\Sheen.JPG)

#### PBR 模型展示

注：为了与Unity Standard 匹配，模型展示部分，光照模型 *PI；

![](..\Docs\images\Cerberus_LP Gesetz.JPG)

![](..\Docs\images\monkey(left-Gesetz right-Standard).JPG)

monkey left-Gesetz right-Standard

![](..\Docs\images\monkey-back(left-Standard right-Gesetz).JPG)

monkey-back(left-Standard right-Gesetz)

![](..\Docs\images\Rustediron-Ball.JPG)

### Cloth Model

![](..\Docs\images\Cloth left - Cloth right - Standard.JPG)

### SubSurface Model

TODO

## Further Work 

**Disney BRDF->Disney BxDF** (近似)

- BSDF

- BTDF
- BSSRDF

**能量守恒**

- Diffuse
  - [Lagarde14] Renormalized Disney Diffuse
  - GDC2017 - PBR Diffuse for GGX+Smith 
  - Siggraph 2018 - COD:WII - Multi-Scattering Diffuse 
  - ...
- Specular Multi-Scattering
  - [Kully&Conty 17]
  - [Lagarde18]] Unity HDRP

**IBL(Image Based Lighting):**

- 添加平面反射，SSR(Screen Space Reflection);



**More Shading Models：**

- Thin Surface

- 虹彩

- PBR 人物渲染
  - skin
  - Hair
  - Eye
  - Cloth

- 体渲染
- 天空、大气渲染

...

**LTCs**

**Specular AA**

**Multi-Layered Material** 

**PBR Work Flow**



**Physical Based Light**

**Physical Based Camera**



**提供Ground Truth 参考** 

## References

[Romain Guy&Mathias Agopian] [Physically Based Rendering in Filament](https://google.github.io/filament/) 中文翻译：[Jerkwin](https://jerkwin.github.io/filamentcn/Filament.md.html#%E6%9D%90%E8%B4%A8%E7%B3%BB%E7%BB%9F/%E9%80%8F%E6%98%8E%E6%B6%82%E5%B1%82%E6%A8%A1%E5%9E%8B)



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



### Further Reading

Extending the Disney BRDF to a BSDF with Integrated Subsurface Scattering



Real-World Measurements for Call of Duty Advanced Warfare

Material Advances in Call of Duty WWII 

Practical Multilayered Materials in Call of Duty Infinite Warfare



[Lagarde18] The road toward unified rendering with Unity’s high definition rendering pipeline



Antialiasing Physically Based Shading with LEADR Mapping 

[Toksvig 05]Mipmapping Normal Maps 

[Kaplanyan 16] Filtering Distributions of Normals for Shading Antialiasing

[Yan et al. 14]Rendering Glints on High-Resolution Normal-Mapped Specular Surfaces

Rock-Solid Shading Image Stability Without Sacrificing Detail



[Heitz 14 b]Importance Sampling Microfacet-Based BSDFs using the Distribution of Visible Normals 



A Journey Through Implementing Multi-scattering BRDFs & Area Lights

Polygonal-Light Shading with Linearly Transformed Cosines（LTC）

Real-Time Area Lighting a Journey from Research to Production 

Real-Time Line- and Disk-Light Shading 



Physically Based Hair Shading in Unreal 

Physically Based Sky, Atmosphere and Cloud Rendering in Frostbite

Practical Real-Time Strategies for Accurate Indirect Occlusion

Separable Subsurface Scattering and Photorealistic Eyes Rendering
