

RP core
AreaLight.hldl
BC6H.hlsl

BSDF.hlsl

ImageBasedLighting.hlsl







## 实现方案

### Direct Lighting

#### **Diffuse Term:**

Lambertian Diffuse；[Burley 12] Disney Diffuse  





#### **Specular Term:**

Cook-Torrance 镜面微表面模型(Specular ):

GGX NDF +G Term: Smith-GGX Height-  Mask-Shadow ??

Schlick Fresnel  y







### Indirect Lighting

IBL(Image Based Lighting)——Light probe(光照探头)，Reflection probe(反射探头，天空盒..)

#### Indirect Diffuse:



#### Indirect Specular :





参数化





对Catlike Coding /Unity/Rendering ——Lighting Shader 的修改项：

1.



2.TBN 

3.IBL



## Further Work 

- 能量守恒
  - Diffuse
  - Specular Multi-Scatter



- IBL:添加平面反射，SSR(Screen Space Reflection);

### TODO List:


Shading Mode：







## 注意事项

- 使用线性颜色空间；
- 
