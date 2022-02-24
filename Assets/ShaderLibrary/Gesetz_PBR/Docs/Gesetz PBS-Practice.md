

## 标椎模型

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



### 参数化



### Clear Coat



### Anisotropy



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



#### PBR 人物模型

TODO

## Further Work 

- 能量守恒
  - Diffuse
  - Specular Multi-Scatter



- IBL:
  - 添加平面反射，SSR(Screen Space Reflection);

### TODO List:


Shading Mode：







## 注意事项

- 使用线性颜色空间；
- 



## References

