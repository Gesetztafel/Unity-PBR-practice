Physically Based Rendering in Filament

# 2 概述

## 2.1 原理

"迪斯尼基于物理的着色"(Physically-based shading at Disney)[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]).



实时移动性能

质量

易用性



## 2.2 基于物理的渲染

具有艺术性,生产效率高；

基于物理的渲染,更准确地表现材质及其与光的相互作用；PBR方法的核心是将材质和光照分离，可以更轻松地创建在所有光照条件下看起来都很精确的真实资源

# 3 符号注记



| 符号  | 定义                                                |
| :---: | :-------------------------------------------------- |
|   v   | 视线单位向量                                        |
|   l   | 入射光线单位向量                                    |
|   n   | 表面法线单位向量                                    |
|   h   | 与 ll 和 vv 对应的半单位向量                        |
|   f   | BRDF                                                |
|  fd   | BRDF的漫反射分量                                    |
|  fr   | BRDF的镜面反射分量                                  |
|   α   | 粗糙度, 来自感知粗糙度`perceptualRoughness`的重映射 |
|   σ   | 漫反射率                                            |
|   Ω   | 球形区域                                            |
|  f0   | 法向入射反射率                                      |
|  f90  | 掠射角反射率                                        |
| χ+(a) | Heaviside函数 (a>0为1, 否则为0)                     |
| nior  | 界面折射率(IOR)                                     |
| ⟨n⋅l⟩ | 点积, 区间限定为[0..1]                              |
|  ⟨a⟩  | 饱和值, (区间限定为[0..1])                          |

**表 1:** 符号与定义

# 4 材质系统

多种材质模型, 用以简化对各种表面特征的描述；将标准模型, 透明涂层模型和各向异性模型结合起来, 形成一个更灵活更强大的模型



## 4.1 标准模型

模型的目标是表现标准材质的外观:

BSDF(双向散射分布函数, Bidirectional Scattering Distribution Function)

BRDF(双向反射分布函数, Bidirectional Reflectance Distribution Function)和

BTDF(双向透射函数, Bidirectional Transmittance Function).



侧重于BRDF, 并且忽略BTDF, 或对其使用很粗糙的近似;正确地模拟具有短的平均自由程的反射, 各向同性, 电介质或导体表面.



BRDF描述中, 标准材质的表面响应由两项组成:

- 漫反射分量或fd

- 镜面反射分量或fr 

  表面, 表面法线, 入射光线和这些项之间的关系如[图 1](https://jerkwin.github.io/filamentcn/Filament.md.html#图_frfd)所示(我们暂时忽略次表面散射):

  

  [![img](https://jerkwin.github.io/filamentcn/images/diagram_fr_fd.png)](https://jerkwin.github.io/filamentcn/images/diagram_fr_fd.png)

**图 1:** 光与表面的相互作用, 使用具有漫反射项 fdfd 和镜面反射项 frfr 的BRDF模型

完整的表面响应可以表示为:

$f(v,l)=f_d(v,l)+f_r(v,l)$(1)

此方程描述了单方向入射光的表面响应. 完整的渲染方程需要在整个半球上对l进行积分.



能够描述光与不规则界面相互作用的模型

微面片BRDF指出, 表面在微观层面上并不光滑, 而是由大量随机排列的平面碎片组成, 这些平面碎片称为微面片

[![img](https://jerkwin.github.io/filamentcn/images/diagram_microfacet.png)](https://jerkwin.github.io/filamentcn/images/diagram_microfacet.png)

**图 2:** 由微面片模型(左)和平面界面模型(右)构建的不规则界面

只有当微面片的法线方向位于光线方向和视线方向中间时, 反射的光才能被看见



[![img](https://jerkwin.github.io/filamentcn/images/diagram_macrosurface.png)](https://jerkwin.github.io/filamentcn/images/diagram_macrosurface.png)

**图 3:** 微面片



[![img](https://jerkwin.github.io/filamentcn/images/diagram_shadowing_masking.png)](https://jerkwin.github.io/filamentcn/images/diagram_shadowing_masking.png)

**图 4:** 微面片的遮蔽和阴影 



*粗糙度* 参数

描述了一个表面在微观层面上的光滑程度(低粗糙度)或粗糙程度(高粗糙度).

表面越光滑滑, 排列整齐的面片越多, 反射光越明显. 表面越粗糙, 朝向相机的面片越少, 入射光反射后就会从相机中散射出去, 从而使镜面高光变得模糊

[图 5](https://jerkwin.github.io/filamentcn/Filament.md.html#图_roughness)展示了不同粗糙度的表面以及光线与它们的相互作用.



[![img](https://jerkwin.github.io/filamentcn/images/diagram_roughness.png)](https://jerkwin.github.io/filamentcn/images/diagram_roughness.png)

**图 5:** 不同粗糙度(从左到右, 从粗糙到光滑)以及对应的BRDF镜面反射分量波瓣



微面片模型由以下方程描述(其中 xx 表示镜面反射分量或漫反射分量):

$$\begin{equation}\ f_X(v,l) = \frac{1}{|n\cdot v| |n\cdot l |}\int_\Omega D(m,\alpha) G(v,l,m) f_m(v,l,m) (v \cdot m) (l \cdot m) dm\end{equation}$$

D项模拟微面片的分布(此项也称为NDF或法向分布函数(Normal Distribution Function)).

G 项模拟微面片的可见度(或遮蔽或阴影遮挡).



由于此方程对镜面反射分量和漫反射分量都有效, 因此不同之处在于微面片BRDF的fm.

此方程用于在 *微观层面* 上对半球进行积分:

[![img](https://jerkwin.github.io/filamentcn/images/diagram_micro_vs_macro.png)](https://jerkwin.github.io/filamentcn/images/diagram_micro_vs_macro.png)

**图 6:** 对单个点的表面响应进行建模需要在微观层面上进行积分



在宏观层面上, 表面被视为是平坦的. 假定从单个方向照亮的着色片段对应于表面上的单个点, 就有助于简化我们的方程.



在微观层面, 表面并不是平坦的, 我们不能再假定单一方向的光线(但我们可以假定入射光线是平行的). 在给定一束平行入射光线的情况下, 由于微面片会向不同的方向散射光, 因此我们必须将半球上的表面响应进行积分, 表面在上图中以m表示



对每个着色片段, 计算微面片在半球上的完整积分是不实际的. 因此, 我们需要对镜面反射分量和漫反射分量的积分进行近似.

## 4.2 电介质和导体

金属(导体)表面;非金属(电介质)表面

当入射光照射到BRDF控制的表面时, 反射光被分为两个独立的分量: 漫反射和镜面反射.

[![img](https://jerkwin.github.io/filamentcn/images/diagram_fr_fd.png)](https://jerkwin.github.io/filamentcn/images/diagram_fr_fd.png)

**图 7:** BSDF的BRDF部分的模型化

[![img](https://jerkwin.github.io/filamentcn/images/diagram_scattering.png)](https://jerkwin.github.io/filamentcn/images/diagram_scattering.png)

**图 8:** 漫反射光的散射

纯金属材料不会发生次表面散射

[![img](https://jerkwin.github.io/filamentcn/images/diagram_brdf_dielectric_conductor.png)](https://jerkwin.github.io/filamentcn/images/diagram_brdf_dielectric_conductor.png)

**图 9:** 电介质和导体表面的BRDF模型化

## 4.3 能量守恒

能量守恒的BRDF表明, 镜面反射和漫反射能量的总和小于入射能量的总和. 

## 4.4 镜面BRDF

镜面反射项 fm,镜面BRDF, 可以使用Fresnel(菲涅耳)定律描述, 在微面片模型积分的Cook-Torrance(库克-托兰斯)近似中以FF表示:
$$f_r(v,l) = \frac{D(h, \alpha) G(v, l, \alpha) F(v, h, f_0)}{4(n⋅v)(n⋅l)}(3)$$

[[Karis13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-karis13)]整理了与这三项有关的一系列公式



### 4.4.1 法向分布函数(镜面D)

[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]观察

长尾法向分布函数(NDF)

[[Walter07](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-walter07)]给出的GGX分布是一种在高光中具有长尾衰减和短峰的分布, 公式简单, 适合实时实现

在现代基于物理的渲染器中, 它也是一种流行的模型, 等价于Trowbridge-Reitz分布.
$$D_{GGX}(h,\alpha) = \frac{a^2}{\pi [ (n⋅h)^2 (a^2 - 1) + 1]^2}(4)$$

```
float D_GGX(float NoH, float roughness) {
    float a = NoH * roughness;
    float k = roughness / (1.0 - NoH * NoH + a * a);
    return k * k * (1.0 / PI);
}
```

使用半精度浮点数
$$|n×h|2=1−(n⋅h)2. $$

```
#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float D_GGX(float roughness, float NoH, const vec3 n, const vec3 h) {
    vec3 NxH = cross(n, h);
    float a = NoH * roughness;
    float k = roughness / (dot(NxH, NxH) + a * a);
    float d = k * k * (1.0 / PI);
    return saturateMediump(d);
}
```

### 4.4.2 几何阴影(镜面G)

Eric Heitz在[[Heitz14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-heitz14)]中表示, Smith几何阴影函数可用于 GG 项, 正确且准确. Smith公式如下:
$$G(v,l,\alpha) = G_1(l,\alpha) G_1(v,\alpha)(6)$$

G1 又可以使用不同的模型, 通常使用GGX公式:
$G_1(v,\alpha) = G_{GGX}(v,\alpha) = \frac{2 (n⋅v)}{n⋅v + \sqrt{a^2 + (1 - a^2) (n⋅v)^2}}$

完整的Smith-GGX公式

$G(v,l,\alpha) = \frac{2 (n⋅l)}{n⋅l + \sqrt{a^2 + (1 - a^2) (n⋅l)^2}} \frac{2 (n⋅v)}{n⋅v + \sqrt{a^2 + (1 - a^2) (n⋅v)^2}}$(8)

分子 2(n⋅l) 和 2(n⋅v)使得我们可以引入可见度函数V对原来的fr函数进行简化:

$f_r(v,l) = D(h, \alpha) V(v, l, \alpha) F(v, h, f_0)$



其中

$V(v,l,\alpha) = \frac{G(v, l, \alpha)}{4(n⋅v)(n⋅l)} = V_1(l,\alpha) V_1(v,\alpha)$

以及:

$V_1(v,\alpha) = \frac{1}{n⋅v+ \sqrt{a^2 + (1 - a^2) (n⋅v)^2}}$ (11)

 Heitz

考虑微面片的高度对遮蔽和阴影的影响, 可以得到更精确的结果

定义了高度相关的Smith函数:

$G(v,l,h,\alpha) = \frac{\chi^+(v⋅h) \chi^+(l⋅h)}{1 + \Lambda(v) + \Lambda(l)}$

$\Lambda(m) = \frac{-1 + \sqrt{1 + a^2 \tan^2\theta_m}}{2} = \frac{-1 + \sqrt{1 + a^2 \frac{1 - \cos^2\theta_m}{\cos^2\theta_m}}}{2}$

将 θm 替换为 n⋅v, 我们得到:

$\Lambda(v) = \frac{1}{2} \left( \frac{\sqrt{a^2 + (1 - a^2)(N\cdot V)^2}}{N\cdot V} - 1 \right)$(14)

可见度函数:

$V(v,l,\alpha) = \frac{0.5}{n⋅l \sqrt{(n⋅v)^2 (1 - α^2) + α^2} + n⋅v\sqrt{(n⋅l)^2 (1 - α^2) + α^2}}$



```
float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = roughness * roughness;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}
```



近似优化

$V(v,l,\alpha) = \frac{0.5}{ n\cdot l [n\cdot v (1 - \alpha) + \alpha] + n\cdot v [ n\cdot l (1 - \alpha) + \alpha]}$(16)

```
float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
    float a = roughness;
    float GGXV = NoL * (NoV * (1.0 - a) + a);
    float GGXL = NoV * (NoL * (1.0 - a) + a);
    return 0.5 / (GGXV + GGXL);
}
```



[[Hammon17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-hammon17)]

$V(v,l,\alpha) = \frac{0.5}{\text{lerp}(2 ( n\cdot l) (n\cdot v),  n\cdot l + n\cdot v, \alpha)}$(17)

### 4.4.3 Fresnel(镜面F)

Fresnel效应,模拟 观察者看到的由表面反射的光的多少取决于观察角度(视角).

反射的光量不仅取决于视角, 还取决于材料的折射率(IOR, index of refraction). 

沿法向入射(垂直入射, 入射光线垂直于表面或入射角为0度)时, 可以根据IOR计算出反射回来的光量 f0, 对于光滑的材料, 以掠射角反射回来的光量 f90 接近100%.



Fresnel项定义了光在两种不同介质的界面处如何反射和折射, 或反射和透射能量的比例. [[Schlick94](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-schlick94)]给出了Cook-Torrance镜面BRDF的Fresnel项的快速近似计算公式:

$F_{Schlick}(v,h,f_0,f_90) = f_0 + (f_{90} - f_0)(1 - v\cdot h)^5$(18)

常数 f0 表示垂直入射时的镜面反射率, 电介质对应的值是单色的, 金属对应的值是多色的.实际值取决于界面的折射率. 



```
vec3 F_Schlick(float VoH, vec3 f0, float f90) {
    return f0 + (vec3(f90) - f0) * pow(1.0 - VoH, 5.0);
}
```





Fresnel函数可以看作在垂直入射镜面反射率 f0 和掠射角反射率 f90 之间进行插值. 

对真实世界材料的观察表明, 电介质和导体在掠射角处都表现出单色镜面反射, 并且90度时的Fresnel反射率为1.0. 

```
vec3 F_Schlick(float VoH, vec3 f0) {
    float f = pow(1.0 - VoH, 5.0);
    return f + f0 * (1.0 - f);
}
```

## 4.5 漫反射BRDF

在漫反射项中, fm为Lambertian函数, BRDF的漫反射项变为:

$f_d(v,l) = \frac{\sigma}{\pi} \frac{1}{| n\cdot v | |  n\cdot l |}\int_\Omega D(m,\alpha) G(v,l,m) (v \cdot m) (l \cdot m) dm$(19)

假定微面片半球具有均匀的漫反射:

fd(v,l)=σ/π(20)

```
float Fd_Lambert() {
    return 1.0 / PI;
}

vec3 Fd = diffuseColor * Fd_Lambert();
```

Lambertian BRDF非常高效, 并且提供的结果与更复杂的模型足够接近.

但是, 漫反射部分最好与镜面反射项一致, 并考虑表面的粗糙度. 

迪斯尼的漫反射BRDF模型[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]和Oren-Nayar模型[[Oren94](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-oren94)]都考虑了粗糙度, 并在掠射角处添加了一些后向反射. 



 [[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]给出的迪斯尼漫反射BRDF

$f_d(v,l) = \frac{\sigma}{\pi} F_{schlick}(n,l,1,f_{90}) F_{schlick}(n,v,1,f_{90})$

其中$f_{90}=0.5 + 2 \cdot \alpha \cos^2\theta_d$(22)



迪斯尼模型在掠射角处展现出一些漂亮的后向反射

```
float F_Schlick(float VoH, float f0, float f90) {
    return f0 + (f90 - f0) * pow(1.0 - VoH, 5.0);
}

float Fd_Burley(float NoV, float NoL, float LoH, float roughness) {
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = F_Schlick(NoL, 1.0, f90);
    float viewScatter = F_Schlick(NoV, 1.0, f90);
    return lightScatter * viewScatter * (1.0 / PI);
}
```



迪斯尼模型在掠射角处展现出一些后向反射



## 4.6 标准模型的总结

**镜面反射项**: 也称高光反射项, 或简称镜面项/高光项, 使用Cook-Torrance镜面微面片模型, 具有GGX法向分布函数, Smith-GGX高度相关的可见度函数, Schlick Fresnel函数.



**漫反射项**: Lambertian漫反射模型.



```
float D_GGX(float NoH, float a) {
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

vec3 F_Schlick(float VoH, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * pow(1.0 - VoH, 5.0);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return 0.5 / (GGXV + GGXL);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

void BRDF(...) {
    vec3 h = normalize(v + l);

    float NoV = abs(dot(n, v)) + 1e-5;
    float NoL = clamp(dot(n, l), 0.0, 1.0);
    float NoH = clamp(dot(n, h), 0.0, 1.0);
    float LoH = clamp(dot(l, h), 0.0, 1.0);

    // 感知线性粗糙度转换为粗糙度(参见[参数化])
    float roughness = perceptualRoughness * perceptualRoughness;

    float D = D_GGX(NoH, a);
    vec3  F = F_Schlick(LoH, f0);
    float V = V_SmithGGXCorrelated(NoV, NoL, roughness);

    // 镜面反射BRDF
    vec3 Fr = (D * V) * F;

    // 漫反射BRDF
    vec3 Fd = diffuseColor * Fd_Lambert();

    // 添加光照 ...
}
```



## 4.7 改进BRDF

能量守恒

### 4.7.1 漫反射的能量增益

todo....

[Lagarde 14] Renormalized Disney Diffuse

[Hammon 17]GDC 2017-GGX_Smith Diffuse

[ 18] COD:WWII 

### 4.7.2 镜面反射的能量损失

Cook-Torrance BRDF 微面片层面,计算光-单次反弹

这种近似会导致高粗糙度时出现能量损失, 表面无法保持能量恒定. 

在单次反弹(或单重散射)模型中, 照射到表面的光线可以被反射到另一个微面片上, 并由于遮蔽和阴影项而被忽略. 然而, 如果我们考虑多次反弹(多重散射), 同一光线可能最终会离开微面片区域, 并被反射回观察者.

[![img](https://jerkwin.github.io/filamentcn/images/diagram_single_vs_multi_scatter.png)](https://jerkwin.github.io/filamentcn/images/diagram_single_vs_multi_scatter.png)

**图 12:** 单重散射(左)与多重散射

基于这个简单的解释, 可以直观地推断出, 因为没有考虑多重散射事件, 表面越粗糙, 能量损失的可能性就越大. 这种能量损失会使粗糙的材质看起来变暗. 金属表面受到的影响特别大, 因为它们的所有反射都是镜面反射. 

[![img](https://jerkwin.github.io/filamentcn/images/material_metallic_energy_loss.png)](https://jerkwin.github.io/filamentcn/images/material_metallic_energy_loss.png)

**图 13:** 由于单重散射, 变暗程度会随粗糙度增大而增加





[![img](https://jerkwin.github.io/filamentcn/images/material_metallic_energy_preservation.png)](https://jerkwin.github.io/filamentcn/images/material_metallic_energy_preservation.png)

**图 14:** 多重散射的能量守恒

可以使用一个白色的物体, 将其置于纯白色的均匀光照环境中, 来验证BRDF的能量守恒性. 

如果达到能量守恒, 纯反射的金属表面(f0=1)应该无法与背景区分开来, 无论该表面的粗糙度如何.

[![img](https://jerkwin.github.io/filamentcn/images/material_furnace_energy_loss.png)](https://jerkwin.github.io/filamentcn/images/material_furnace_energy_loss.png)

**图 15:** 由于单重散射导致变暗程度随粗糙度增大而增加





[![img](https://jerkwin.github.io/filamentcn/images/material_furnace_energy_preservation.png)](https://jerkwin.github.io/filamentcn/images/material_furnace_energy_preservation.png)

**图 16:** 多重散射可以保证能量守恒







[[Heitz16](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-heitz16)] 多重散射BRDF的随机估计—— mean free path;遗憾的是, 论文只给出了多重散射BRDF的随机估计.

因此, 其解决方法不适用于实时渲染.[[Kulla17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-kulla17)] Kulla&Conty:添加一个能量补偿项,作为额外BRDF波瓣

$f_{ms}(l,v)=\frac{(1−E(l))(1−E(v))F^2_{avg}E_{avg}}{π(1−E_{avg})[1−F_{avg}(1−E_{avg})]}$(23)

E,镜面反射BRDF fr 的方向反照率,f0设置为1:

E(l)=∫Ωf(l,v)(n⋅v)dv(24)

Eavg 项为 E 的余弦加权平均值:

$Eavg=2∫^1_0E(μ)μdμ$(25)

Favg 为Fresnel项的余弦加权平均值:

$F_{avg}=2∫^1_0F(μ)μdμ$(26)

E 和 Eavg 预先计算好并存储在查找表中,使用Schlick近似,Favg 可以大大化简:

$F_{avg}=\frac{1+20f_0}{21}$(27)

与原来的单重散射波瓣, fr, 结合

$f_r(l,v)=f_{ss}(l,v)+f_{ms}(l,v)$

[[Lagarde18](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-lagarde18)],简化为 f0,建议通过添加缩放的GGX镜面反射波瓣来进行能量补偿:

$f_{ms}(l,v)=f_0\frac{1−E(l)}{E(l)}f_{ss}(l,v)$(29)

关键洞察E:(l)不仅可以预先计算, 而且还可以与基于图像的光照预积分结合在一起

$fr(l,v)=f_{ss}(l,v)+f_0(1/r−1)f_{ss}(l,v)$(30)

$r=∫_ΩD(l,v)V(l,v)⟨n⋅l⟩dl$ ,将 r存储在DFG查找表中,

```
vec3 energyCompensation = 1.0 + f0 * (1.0 / dfg.y - 1.0);
// 缩放镜面波瓣以考虑多重散射
Fr *= pixel.energyCompensation;
```

**清单 10:** 能量补偿镜面反射波瓣的实现



## 4.8 参数化

[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)] 迪斯尼材质模型



### 4.8.1 标准参数

|                             参数 | 定义                                                         |
| -------------------------------: | :----------------------------------------------------------- |
|               **BaseColor 基色** | 非金属表面的漫反射, 金属表面的镜面反射                       |
|              **Metallic 金属度** | 表面属于电介质(0.0)还是导体(1.0). 通常作为二进制值(0或1)     |
|             **Roughness 粗糙度** | 表面的感知光滑程度(0.0)或粗糙程度(1.0). 光滑的表面会呈现出清晰的反射 |
|           **Reflectance 反射率** | 垂直入射时电介质表面的Fresnel反射率. 此项代替了明确的折射率  |
|              **Emissive 自发光** | 额外的漫反射反照率, 用于模拟发光表面(如霓虹灯等). 此参数主要用于具有泛光通道的HDR管线 |
| **Ambient occlusion 环境光遮蔽** | 定义一个表面点接收环境光的程度. 它是每像素的阴影因子, 介于0.0和1.0之间. 此参数将在光照章节中详细讨论 |

**表 2:** 标准模型的参数

[![img](https://jerkwin.github.io/filamentcn/images/material_parameters.png)](https://jerkwin.github.io/filamentcn/images/material_parameters.png)

**图 17:** 从上到下: 变化的金属度参数, 变化的电介质粗糙度, 变化的金属粗糙度, 变化的反射率

### 4.8.2 类型和范围

|                             参数 | 类型和范围                |
| -------------------------------: | :------------------------ |
|               **BaseColor 基色** | 线性RGB [0..1]            |
|              **Metallic 金属度** | 标量 [0..1]               |
|             **Roughness 粗糙度** | 标量 [0..1]               |
|           **Reflectance 反射率** | 标量 [0..1]               |
|              **Emissive 自发光** | 线性RGB [0..1] + 曝光补偿 |
| **Ambient occlusion 环境光遮蔽** | 标量 [0..1]               |



### 4.8.3 重映射

重新映射参数 *基色*, *粗糙度* 和 *反射率*.

#### 4.8.3.1 基色重映射

材质的基色受材质自身的"金属度"影响. 

电介质具有单色镜面反射, 但仍保留其基色作为漫反射颜色.

另一方面, 导体使用其基色作为镜面反射颜色, 但没有漫反射分量.

光照方程必须使用漫反射颜色和 f0f0 而不是基色.

```
vec3 diffuseColor = (1.0 - metallic) * baseColor.rgb;
```

**清单 11:** 基色与漫反射颜色转换的GLSL实现



#### 4.8.3.2 反射率重映射

**电介质**

Fresnel项依赖于 f0f0, 即对应法向入射的镜面反射率, 并且对电介质而言是单色的. 

[[Lagarde14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-lagarde14)]给出的电介质表面的重映射:

f0=0.16⋅reflectance2(32)

目标是将 f0f0 映射到一个范围, 该范围可以不是普通电介质表面(4%反射率)和宝石表面(8%至16%)的Fresnel值. 

[![img](https://jerkwin.github.io/filamentcn/images/diagram_reflectance.png)](https://jerkwin.github.io/filamentcn/images/diagram_reflectance.png)

**图 18:** 常见反射率的值

如果已知折射率(例如, 空气-水界面的IOR为1.33), 可以根据下式计算Fresnel反射率:

$f_0(n_{ior}) = \frac{(n_{ior} - 1)^2}{(n_{ior} + 1)^2}$(33)

如果已知反射率, 则可以计算相应的IOR:

$n_{ior}=\frac{2}{1-\sqrt{f_0}}-1$(34)

|                                      材料 | 反射率   | 线性值     |
| ----------------------------------------: | :------- | :--------- |
|                                  水 Water | 2%       | 0.35       |
|                               纤维 Fabric | 4%到5.6% | 0.5到0.59  |
|                   常见液体 Common liquids | 2%到4%   | 0.35到0.5  |
|                 常见宝石 Common gemstones | 5%到16%  | 0.56到1.0  |
|                塑料, 玻璃 Plastics, glass | 4%到5%   | 0.5到0.56  |
| 其他电介质材料 Other dielectric materials | 2%到5%   | 0.35到0.56 |
|                                 眼睛 Eyes | 2.5%     | 0.39       |
|                                 皮肤 Skin | 2.8%     | 0.42       |
|                                 毛发 Hair | 4.6%     | 0.54       |
|                                牙齿 Teeth | 5.8%     | 0.6        |
|                                    默认值 | 4%       | 0.5        |

**表 4:** 常见材料的反射率 (来源: Real-Time Rendering 第4版)

|        金属 |  f0f0 的sRGB值   | 十六进制颜色值 | 颜色 |
| ----------: | :--------------: | :------------: | :--- |
|   银 Silver | 0.97, 0.96, 0.91 |    #f7f4e8     |      |
| 铝 Aluminum | 0.91, 0.92, 0.92 |    #e8eaea     |      |
| 钛 Titanium | 0.76, 0.73, 0.69 |    #c1baaf     |      |
|     铁 Iron | 0.77, 0.78, 0.78 |    #c4c6c6     |      |
| 铂 Platinum | 0.83, 0.81, 0.78 |    #d3cec6     |      |
|     金 Gold | 1.00, 0.85, 0.57 |    #ffd891     |      |
|  黄铜 Brass | 0.98, 0.90, 0.59 |    #f9e596     |      |
|   铜 Copper | 0.97, 0.74, 0.62 |    #f7bc9e     |      |

**表 5:** 常见金属的 f0

在掠射角处, 所有材质的Fresnel反射率都是100%, 因此在计算镜面反射BRDF的 frfr 时, 我们按以下方式设置 f90:

f90=1.0(35)

**导体**

金属表面的镜面反射是多色的:

f0=baseColor⋅metallic(36)

```
vec3 f0 = 0.16 * reflectance * reflectance * (1.0 - metallic) + baseColor * metallic;
```

#### 4.8.3.3 粗糙度重映射和区间限定

将其重新映射到感知线性范围:

α=perceptualRoughness^2(37)

重新映射的粗糙度更容易为美工和开发人员所理解.

简单的平方重映射给出的结果视觉上令人满意, 也很直观, 同时对于实时应用来说还很便宜.



1 Frostbite引擎将解析灯光的粗糙度限定为0.045, 以减少镜面锯齿. 使用单精度浮点数(fp32)时可以这样做.

### 4.8.4 混合和分层

[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]和[[Neubelt13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-neubelt13)]

只需要对不同的参数进行简单插值, 这个模型就可以在不同材质之间进行稳健的混合. 特别是, 它允许使用简单的遮蔽对不同的材质进行分层.

材质的混合和分层实际上是对材质模型各种参数的插值. 

### 4.8.5 制作基于物理的材质

基色, 金属度, 粗糙度和反射率的本质, 设计基于物理的材质就变得相当容易.

[![img](https://jerkwin.github.io/filamentcn/images/material_chart.jpg)](https://jerkwin.github.io/filamentcn/images/material_chart.jpg)

制作基于物理的材质

此外, 以下是如何使用我们的材质模型的快速总结:

- 所有材质:

  **基色** 不应含有光照信息, 但微遮蔽除外.

  **金属度** 几乎是一个二进制值. 纯导体的金属度为1, 纯电介质的金属度为0. 你应该尝试使用接近0和1的值. 中间的值用于表面类型之间的过渡(例如金属到生锈).

- 非金属材质

  **基色** 代表反射颜色, 应为sRGB值, 范围为50-240(严格范围)或30-240(容差范围).

  **金属度** 应为0或接近0.

  **反射率** 如果找不到合适值, 应设置为127 sRGB(0.5线性, 4%反射率). 不要使用低于90 sRGB(0.35线性, 2%反射率)的值.

- 金属材质

  **基色** 代表镜面反射颜色和反射率. 使用光度为67%至100%(170-255 sRGB)的值. 氧化或脏的金属应使用比清洁金属更低的光度以考虑非金属成分.

  **金属度** 应为1或接近1.

  **反射率** 忽略(根据基色计算).



### 4.9 透明涂层模型

标准材质模型非常适用于由单层构成的各向同性表面.

标准层上有一个薄的半透明层的材质



通过添加第二个镜面反射波瓣, 可以将透明涂层作为标准材质模型的扩展,要计算第二个镜面反射BRDF. 

为了简化实施和参数化, 透明涂层将始终是各向同性的电介质. 基本层可以是标准模型中的任何对象(电介质或导体).

由于入射光会穿过透明涂层, 我们必须考虑能量损失

[![img](https://jerkwin.github.io/filamentcn/images/diagram_clear_coat.png)](https://jerkwin.github.io/filamentcn/images/diagram_clear_coat.png)

**图 24:** 透明涂层表面模型

#### 4.9.1 透明涂层镜面BRDF

透明涂层同样使用标准模型中的Cook-Torrance微面片BRDF进行建模. 

透明涂层始终是各向同性的电介质, 粗糙度较低;可以选择更便宜的DFG项而不会导致视觉质量明显降低.



对[[Karis13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-karis13)]和[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]中列出各项进行的调查表明, 我们已经在标准模型中使用的Fresnel和NDF项在计算上并不比其他项更昂贵. [[Kelemen01](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-kelemen01)]给出了一个更简单的公式, 可以取代我们的Smith-GGX可见度项:

$V(l,h) = \frac{1}{4(L\cdot H)^2}$

遮蔽阴影函数不是基于物理的, 如[[Heitz14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-heitz14)]指出, 但简单性使它非常适用于实时渲染.

Cook-Torrance镜面微面片模型, 具有GGX法向分布函数, Kelemen可见度函数和Schlick Fresnel函数.

```
float V_Kelemen(float LoH) {
    return 0.25 / (LoH * LoH);
}
```

**有关Fresnel项的说明**

镜面BRDF的Fresnel项需要 f0f0, 即对应法向入射角的镜面反射率. 

可以根据界面的折射率计算. 假定透明涂层由聚氨酯组成, 这是一种常见的化合物, [用于涂料和清漆](https://en.wikipedia.org/wiki/List_of_polyurethane_applications#Varnish)或类似物. 空气-聚氨酯界面的[IOR为1.5](http://www.clearpur.com/transparent-polyurethanes/), 由此我们可以计算出 f0:

f_0(1.5)=..=0.04,对应于普通电介质材料.

#### 4.9.2 表面响应中的积分

必须考虑到添加透明涂层造成的能量损失

$f(v,l)=f_d(n,l) (1 - F_c) + f_r(n,l) (1 - F_c)^2 + f_c(n,l)$

Fc 为透明涂层BRDF的Fresnel项,fc 为透明涂层BRDF. 

将镜面反射分量乘以 (1−Fc)2是为了在光进入并留在透明涂层时保持能量守恒. 将漫反射分量乘以 1−Fc 是尝试保证能量守恒.

#### 4.9.3 透明涂层参数化

|                              参数 | 定义                                             |
| --------------------------------: | :----------------------------------------------- |
|            **ClearCoat 涂层强度** | 透明涂层的强度. 介于0和1之间的标量               |
| **ClearCoatRoughness 涂层粗糙度** | 透明涂层的感知光滑度或粗糙度. 介于0和1之间的标量 |

透明涂层粗糙度的范围从[0..1]降低为较小的[0..0.6]. 

```
void BRDF(...) {
    // 根据标准模型计算Fd和Fr.

    // 重新映射和线性化透明涂层的粗糙度
    clearCoatPerceptualRoughness = mix(0.089, 0.6, clearCoatPerceptualRoughness);
    clearCoatRoughness = clearCoatPerceptualRoughness * clearCoatPerceptualRoughness;

    // 透明涂层BRDF
    float  Dc = D_GGX(clearCoatRoughness, NoH);
    float  Vc = V_Kelemen(clearCoatRoughness, LoH);
    float  Fc = F_Schlick(0.04, LoH) * clearCoat; // clear coat strength
    float Frc = (Dc * Vc) * Fc;

    // 考虑基层的能量损失
    return color * ((Fd + Fr * (1.0 - Fc)) * (1.0 - Fc) + Frc);
}
```

#### 4.9.4 基层的修改

重新计算 f0,通常基于空气-材料界面

基层需要基于透明涂层-材质界面来计算 f0

先根据 f0 计算材质的折射率(IOR), 再根据新计算的IOR和透明涂层的IOR(1.5)计算新的 f0.

首先, 计算基层的IOR:

$IOR_{base}=\frac{1+\sqrt{f_0}}{1-\sqrt{f_0}}$

然后, 根据这个新得到的折射率计算新的 f0:

$f_{0base}=(\frac{IOR_{base}-1.5}{IOR_{base}+1.5})^2$

由于透明涂层的IOR是固定的, 可以将两个步骤结合起来进行简化:

$f_{0_{base}} = \frac{\left( 1 - 5 \sqrt{f_0} \right) ^2}{\left( 5 - \sqrt{f_0} \right) ^2}$

还应该根据透明涂层的IOR来修改基层的表观粗糙度

### 4.10 各向异性模型

各向异性模型

#### 4.10.1 各向异性镜面BRDF

对先前的各向同性镜面BRDF进行修改以处理各向异性材质. Burley使用各向异性GGX NDF实现了这一目标:

$D_{aniso}(h,\alpha) = \frac{1}{\pi \alpha_t \alpha_b} \frac{1}{[(\frac{t \cdot h}{\alpha_t})^2 + (\frac{b \cdot h}{\alpha_b})^2 + ( n\cdot h)^2]^2}$

依赖于两个辅助粗糙度项: 沿副切线方向的粗糙度 αb, 以及沿切线方向的粗糙度 αt.

 [[Neubelt13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-neubelt13)]$\alpha_t = \alpha \\\alpha_b = \text{lerp}(0, \alpha, 1 - \text{anisotropy})$

[[Burley12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-burley12)]$\alpha_t = \frac{\alpha}{\sqrt{1 - 0.9 \times \text{anisotropy} } } \\\alpha_b = \alpha \sqrt{1 - 0.9 \times \text{anisotropy} }$

[[kulla17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-kulla17)],可以创建尖锐的高光:

$\alpha_t = \alpha \times (1 + \text{anisotropy}) \\\alpha_b = \alpha \times (1 - \text{anisotropy})$

请注意, 除法线方向外, 还需要切线方向和副切线方向. 

```
float at = max(roughness * (1.0 + anisotropy), 0.001);
float ab = max(roughness * (1.0 - anisotropy), 0.001);

float D_GGX_Anisotropic(float NoH, const vec3 h,
        const vec3 t, const vec3 b, float at, float ab) {
    float ToH = dot(t, h);
    float BoH = dot(b, h);
    float a2 = at * ab;
    highp vec3 v = vec3(ab * ToH, at * BoH, a2 * NoH);
    highp float v2 = dot(v, v);
    float w2 = a2 / v2;
    return a2 * w2 * w2 * (1.0 / PI);
}
```

**清单 15:** Burley各向异性NDF的GLSL实现

此外, [[Heitz14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-heitz14)]提出了一个各向异性遮蔽-阴影函数, 用于匹配高度相关的GGX分布. 通过使用可见度函数, 可以大大地简化遮蔽-阴影项:

$G(v,l,h,\alpha) = \frac{\chi^+( v\cdot h) \chi^+( l\cdot h)}{1 + \Lambda(v) + \Lambda(l)}$

$\Lambda(m) = \frac{-1 + \sqrt{1 + \alpha_0^2 \tan^2\theta_m}}{2} = \frac{-1 + \sqrt{1 + \alpha_0^2 \frac{1 - \cos^2 \theta_m}{\cos^2 \theta_m}}}{2}$

其中 $\alpha_0 = \sqrt{\cos^2 \phi_0 \alpha_x^2 + \sin^2 \phi_0 \alpha_y^2}$

推导后:$V_{aniso}( n\cdot l, n\cdot v,\alpha) = \frac{1}{2[( n\cdot l)\hat{\Lambda}_v+( n\cdot v)\hat{\Lambda}_l]} \\\hat{\Lambda}_v = \sqrt{\alpha^2_t(t \cdot v)^2+\alpha^2_b(b \cdot v)^2+( n\cdot v)^2} \\\hat{\Lambda}_l = \sqrt{\alpha^2_t(t \cdot l)^2+\alpha^2_b(b \cdot l)^2+( n\cdot l)^2}$

每条光线的 Λ^v 项都相同, 如果需要只计算一次即可.

```
float at = max(roughness * (1.0 + anisotropy), 0.001);
float ab = max(roughness * (1.0 - anisotropy), 0.001);

float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float ToV, float BoV,
        float ToL, float BoL, float NoV, float NoL) {
    float lambdaV = NoL * length(vec3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(vec3(at * ToL, ab * BoL, NoL));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturateMediump(v);
}
```

**清单 16:** 各项异性可见度函数的GLSL实现

#### 4.10.2 各向异性参数化

各向异性材质模型包含先前为标准材质模型定义的所有参数

|                      参数 | 定义                              |
| ------------------------: | :-------------------------------- |
| **Anisotropy 各向异性度** | 各向异性程度. 介于-1和1之间的标量 |

注意, 负值会使各向异性平行于副切线方向, 而不是平行于切线方向.

### 4.11 次表面模型

TODO

#### 4.11.1 次表面镜面反射BRDF

#### 4.11.2 次表面参数化

### 4.12 布料模型

衣服和织物通常由松散连接的线制成, 这些线可以吸收和散射入射光. 



布料的特点是镜面波瓣更加柔和, 具有较大的衰减, 以及由前向/后向散射引起的模糊光照.

有些织物还会呈现出双色调镜面反射颜色(例如天鹅绒).

由于前向散射和后向散射, 这类织物(天鹅绒)表现出强烈的边缘照明. 这些散射事件是由直立在织物表面的纤维引起的. 当入射光与视线方向相反时, 纤维会向前散射光. 同样, 当入射光与视线方向相同时, 纤维会向后散射光.



由于纤维很柔软, 理论上应该模拟修整表面的能力. 

模拟了一个可见的前向镜面反射贡献, 这可归因于纤维方向的随机变化.



对有些类型的织物, 使用硬表面材质模型仍然是最好的. 例如, 皮革, 丝绸和缎子

#### 4.12.1 布料镜面BRDF

布料镜面BRDF  改进,微面片BRDF,来自Ashikhmin&Premoze在[[Ashikhmin07](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-ashikhmin07)]中的描述:

分布项对BRDF的贡献最大, 并且阴影/遮蔽项对于他们的天鹅绒分布来说并不是必需的. 分布项本身就是一个反向高斯分布. 

有助于实现模糊光照(前向散射和后向散射), 同时添加了偏移以模拟前向镜面反射的贡献.

天鹅绒NDF:$$D_{velvet}(v,h,α)=c_{norm}[1+4exp(\frac{−cot^2θ_h}{α^2})]$$

[[Ashikhmin00](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-ashikhmin00)]中描述的NDF的变体,并进行了特别的修改以包含偏移(此处设置为1)和幅度(4)

[[Neubelt13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-neubelt13)],Neubelt&Pettineo,NDF的归一化版本:

$$D_{velvet}(v,h,α)=\frac{1}{\pi(1+4α^2)}[1+4(\frac{exp(\frac{−cot^2θ_h}{α^2})}{sin^4θ_h})]$$

对于完整的镜面BRDF, 遵循[[Neubelt13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-neubelt13)],并用更平滑的变体替代了传统的分母:

$$f_r(v,h,α)=\frac{D_{velvet}(v,h,α)}{4[n⋅l+n⋅v−(n⋅l)(n⋅v)]}$$

天鹅绒NDF ,半浮点优化,并使用三角恒等式避免计算昂贵的余切.

```
float D_Ashikhmin(float roughness, float NoH) {
    // Ashikhmin 2007, "Distribution-based BRDFs"
	float a2 = roughness * roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}
```

[[Estevez17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-estevez17)],Estevez&Kulla提出NDF,"Charlie"光泽,于指数正弦而不是反向高斯.  它的参数化感觉更自然, 更直观, 它提供了更柔和的外观, 并且它的实现更简单

$$D(m)=\frac{(2+1/α)sinθ^{1/α}}{2\pi}$$

[[Estevez17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-estevez17)],提出了一个新的阴影项, 在这里省略, 因为计算成本很高.相反, 使用[[Neubelt13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-neubelt13)]中的可见度项

```
float D_Charlie(float roughness, float NoH) {
    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    float invAlpha  = 1.0 / roughness;
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}
```



##### 4.12.1.1  光泽颜色

为了更好地控制布料的外观, 并使用户能够重新创建双色调镜面反射材质, 我们引入了直接修改镜面反射率的功能. 

光泽颜色"(sheen color)

#### 4.12.2  布料漫反射BRDF

修改Lambertian漫反射BRDF. 以满足能量守恒, 并提供了可选的次表面散射项. 并不是基于物理的, 可用于模拟特定类型织物中光的散射, 部分吸收和再发射.

不含可选次表面散射的漫反射项:

$$f_d(v,h)=\frac{c_{diff}}{π}(1−F(v,h))$$

F(v,h)F(v,h) 为方程 48 中布料镜面反射BRDF的Fresnel项

在实践中, 我们选择省略漫反射分量中的 1−F(v,h) 项. 

效果有点微妙, 我们认为这不值得增加计算成本.



次表面散射是使用包裹漫反射光照技术实现的, 其能量守恒形式为:

$$f_d(v,h)=\frac{c_{diff}}{π}(1−F(v,h))⟨n⋅l+\frac{w}{(1+w)}⟩⟨c_{subsurface}+n⋅l⟩$$(51)

w 为介于0和1之间的值, 定义了漫反射光围绕终结器的程度.为避免引入另一个参数, 固定 w=0.5.

请注意, 使用包裹漫反射光照时, 漫反射项不能乘以 n⋅l. 

```
// 镜面BRDF
float D = distributionCloth(roughness, NoH);
float V = visibilityCloth(NoV, NoL);
vec3  F = sheenColor;
vec3 Fr = (D * V) * F;

// 漫反射BRDF
float diffuse = diffuse(roughness, NoV, NoL, LoH);
#if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
// energy conservative wrap diffuse
diffuse *= saturate((dot(n, light.l) + 0.5) / 2.25);
#endif
vec3 Fd = diffuse * pixel.diffuseColor;

#if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
// 便宜的次表面散射
Fd *= saturate(subsurfaceColor + NoL);
vec3 color = Fd + Fr * NoL;
color *= (lightIntensity * lightAttenuation) * lightColor;
#else
vec3 color = Fd + Fr;
color *= (lightIntensity * lightAttenuation * NoL) * lightColor;
#endif
```

#### 4.12.3 布料参数化

除 *金属度* 和 *反射率* 参数外, 布料材质模型包含了先前为标准材质模型定义的所有参数.

|                           参数 | 定义                                                         |
| -----------------------------: | :----------------------------------------------------------- |
|        **SheenColor 光泽颜色** | 用于创建双色调镜面反射织物的高光色调(默认值为0.04以匹配标准反射率) |
| **SubsurfaceColor 次表面颜色** | 经材料散射和吸收后的漫反射颜色                               |

要创建类似天鹅绒的材质, 可以将基色设置为黑色(或深色). 并将光泽颜色设置为所需的色度信息.

创建更常见的面料, 如牛仔布, 棉布等, 请使用基色作为色度, 并使用默认的光泽颜色或将光泽颜色设置为基色的亮度

## 5 光照

光照环境的正确性和一致性;

灯光 支持,分为两类, 直接光照和间接光照:

**直接光照**: 点光源, 光度学光源, 面光源.

**间接光照**: 基于图像的灯光(IBL), 用于局部[2](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-localprobesmobile)和远程光探头.



### 5.1 单位

|                                  光度学术语 | 符号 | 单位                              |
| ------------------------------------------: | :--: | :-------------------------------- |
|              光通量/发光功率 Luminous power |  Φ   | Lumen (lm) 流明                   |
|            光度/发光强度 Luminous intensity |  I   | Candela (cd) 或 lm/sr 坎德拉/烛光 |
|                            照度 Illuminance |  E   | Lux (lx) 或 lm/m2 勒克斯          |
|                         亮度/辉度 Luminance |  L   | Nit (nt) 或 cd/m2 尼特            |
|                      辐射功率 Radiant power |  Φe  | Watt (W) 瓦特                     |
|             光效/发光效率 Luminous efficacy |  η   | Lumens per watt (lm/W) 流明每瓦特 |
| 发光比率/光源能量利用率 Luminous efficiency |  V   | 百分比 (%)                        |

TODO

...

|                                灯光类型 | 单位                           |
| --------------------------------------: | :----------------------------- |
|                平行光 Directional light | 照度 Illuminance (lx 或 lm/m2) |
|                      点光源 Point light | 发光功率 Luminous power (lm)   |
|                       聚光灯 Spot light | 发光功率 Luminous power (lm)   |
|            光度测量灯 Photometric light | 光度 Luminous intensity (cd)   |
| 遮蔽光度测量灯 Masked photometric light | 发光功率 Luminous power (lm)   |
|                       面光源 Area light | 发光功率 Luminous power (lm)   |
|        基于图像的灯光 Image based light | 亮度 Luminance (cd/m2)         |

...

#### 5.1.1 灯光单位验证

##### 5.1.1.1 照度

##### 5.1.1.2 亮度

##### 5.1.1.3 发光强度



$I=E⋅d^2$

### 5.2 直接光照

...

#### 5.2.1 平行光

#### 5.2.2 精准光源

##### 5.2.2.1 点光源

##### 5.2.2.2 聚光灯

##### 5.2.2.3 衰减函数

#### 5.2.3 光度学光源

#### 5.2.4 面光源

LTCs

#### 5.2.5 光源参数化

与标准材质模型的参数化类似, 目标是让光源参数化直观且易于美工和开发人员使用. 

着这种精神, 我们决定将光源颜色(或色调)与光源强度分开.

因此, 光源颜色定义为线性RGB颜色(或者为了方便, 在工具UI中使用sRGB).



|                               参数 | 定义                                                         |
| ---------------------------------: | :----------------------------------------------------------- |
|                      **类型 Type** | Directional平行光, point点光源, spot聚光灯, area面光源       |
|                 **方向 Direction** | 用于平行光, 点光源, 光度学点光源, 线状和管状面光源(方向性)   |
|                     **颜色 Color** | 发射光的颜色, 线性RGB颜色. 在工具中可以使用sRGB颜色或色温指定 |
|                 **强度 Intensity** | 灯光的亮度. 单位取决于光源类型                               |
|        **Falloff radius 衰减半径** | 最大影响距离                                                 |
|             **Inner angle 内锥角** | 聚光灯内圆锥体的角度, 以度为单位                             |
|             **Outer angle 外锥角** | 聚光灯外圆锥体的角度, 以度为单位                             |
|                    **Length 长度** | 面光源的长度, 用于创建线性或管状灯光                         |
|                    **Radius 半径** | 面光源的半径, 用于创建球形或管状灯光                         |
| **Photometric profile 光度学轮廓** | 表示光度学光源轮廓的纹理, 只能用于精准光源                   |
|        **Masked profile 遮蔽轮廓** | 布尔值, 指示是否将IES轮廓用作遮蔽. 作为遮蔽时, 光源的亮度会乘以一个因子, 这个因子为用户指定的强度与积分IES轮廓强度之比. 如果不用作遮蔽, 会忽略用户指定的强度, 但使用IES乘数代替 |
|                       **光度乘数** | 光度学光源的亮度乘数(如果禁用IES遮蔽)                        |

**注意**: 为了简化实现, 在发送到着色器之前, 所有发光功率都会转换为发光强度(cdcd). 转换依赖于光源, 前面几节对此有所说明.

**注意**: 可以从其他参数推断光源类型(例如, 点光源的长度, 半径, 内角和外角都为0).

##### 5.2.5.1 色温

#### 5.2.6 预曝光灯光


### 5.3 基于图像的光照(IBL)

在现实生活中, 光来自各个方向, 或是直接来自光源, 或是间接来自环境中物体的反弹, 并在这个过程中被部分吸收. 在某种程度上, 可以将物体周围的整个环境视为光源. 图像, 特别是立方体贴图, 是编码这种"环境光"的好方法. 这称为基于图像的光照(IBL), 或有时称为间接光照.



基于图像的光照存在局限性. 显然, 必须以某种方式获取环境图像, 正如我们将在下面看到的那样, 在将其用于光照之前, 需要进行预处理. 通常, 环境图像是在现实世界中离线获取的, 或者由引擎离线或实时生成; 无论哪种方式, 都需要使用局部或远程探头.



探头可用于获取远程或局部的环境.



整个环境都会为物体表面上的特定点提供光; 这称为*辐照度* (E). 从物体反弹出的光称为辐射(Lout). 入射光照必须一致性地用于BRDF的漫反射和镜面反射部分.



基于图像的光照(IBL)的辐照度和材质模型(BRDF) f(Θ)f(Θ)[5](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-ibl1)之间的相互作用所产生的辐射 LoutLout 的计算方法如下:

$L_{out}(n,v,Θ)=∫_Ωf(l,v,Θ)L_⊥(l)⟨n⋅l⟩dl$(76)



### 5.3.1 IBL类型

- 远程光探头, 用于捕捉"无限远"处的光照信息, 可以忽略视差. 远程探头通常包括天空, 远处的景观特征或建筑物等. 它们可以由渲染引擎捕捉, 也可以高动态范围图像(HDRI)的形式从相机获得.

- 局部光探头, 用于从特定角度捕捉世界的某个区域. 捕捉会投影到立方体或球体上, 具体取决于周围的几何体. 局部探头比远程探头更精确, 在为材质添加局部反射时特别有用.

- 平面反射, 用于通过渲染镜像场景来捕捉反射. 此技术只适用于平面, 如建筑地板, 道路和水.

- **屏幕空间反射**, 基于在深度缓冲区使用光线行进方法渲染的场景(例如使用前一帧)来捕捉反射. SSR效果很好, 但可能非常昂贵.

必须区分静态和动态IBL. 实现完全动态的昼夜循环需要动态地重新计算远程光探头[6](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-ibltypes1). 平面和屏幕空间反射本质都是动态的.



### 5.3.2 IBL单位

IBL将使用亮度单位 cd/m2,是所有直接光照方程的输出单位.对于引擎捕获的光探头(动态或静态离线)使用亮度单位非常简单.



为正确地重建HDRI的亮度用于IBL, 美工必须做的不只是简单地拍摄环境照片, 还要记录额外的信息:

- 颜色校准: 使用灰度卡或MacBeth ColorChecker
- 相机设置: 光圈, 快门和ISO
- **亮度样本**: 使用光点/亮度计

测量并列出常用亮度值(晴空, 内部等)

### 5.3.3 处理光探头

IBL的辐射度是通过在表面半球上进行积分来计算的. 

必须首先对光探头进行预处理, 将它们转换为更适合实时交互的格式.

- 镜面反射率: 预滤波重要性采样与拆分求和近似
- **漫反射率**: 辐照度贴图和球谐函数

### 5.3.4 远程光探头

#### 5.3.4.1 漫反射BRDF积分

Lambertian BRDF

$$f_d(σ)=\frac{σ}{π}\\L_d(n,σ)=∫_Ωf_d(σ)L_⊥(l)⟨n⋅l⟩dl\\=\frac{σ}{π} ∫_ΩL_⊥(l)⟨n⋅l⟩dl\\=\frac{σ}{π}E_d(n)$$

辐照度 $$E_d(n)=∫_ΩL_⊥(l)⟨n⋅l⟩dl$$

在离散域中:$$E_d(n)≡\underset{∀i∈image}{∑}L_⊥(s_i)⟨n⋅s_i⟩Ω_s$$

Ωs 为与样本 i 相关联的立体角



辐照度积分 Ed 可以简单地, 尽管很慢9, 预先计算并存储到立方体贴图中, 以便在运行时可以高效访问. 通常, *image* 是一个立方体贴图或等距矩形图像.σ/π项独立于IBL, 在运行时添加以获得*辐照度*.



5 Θ 代表材质模型 f 的参数, 即: *粗糙度*, 反照度等......

6 这可以通过混合静态探头, 或通过随时间推移工作负载来完成

7 Lambertian BRDF 不依赖于  l→,  v→ 或 θ, 因此$ L_d(n,v,θ)≡L_d(n,σ)$

8 对于立方体贴图, Ωs 可以使用 $\frac{2π}{6⋅width⋅height}$近似

9 $O(12n^2m^2)$, n 和 m 分别为环境尺寸和预计算的立方体贴图



然而, 辐照度也可以通过分解为球谐函数(SH)进行实时计算, 所得结果非常接近精确值并且成本不高. 

通常最好避免在移动设备上获取纹理, 并释放纹理单元. 即使将其存储到立方体贴图中, 使用SH分解预先计算积分, 然后再渲染也要快几个数量级.



SH分解在概念上类似于傅里叶变换, 它以频域中的正交基表示信号. 

- 编码⟨cosθ⟩只需要很少的系数
- 对具有 *圆对称* 的内核进行卷积非常便宜, 并且结果为SH空间中的乘积

在实践中, ⟨cosθ⟩只要4或9个系数(即: 2或3个波段),这意味着 L⊥ 同样不需要更多系数.

在实践中, 我们使用 ⟨cosθ⟩ 对L⊥ 进行预卷积, 并使用基本缩放因子 Kml 预先缩放这些系数, 以便着色器中的重建代码尽可能简单:

```glsl
vec3 irradianceSH(vec3 n) {
    // uniform vec3 sphericalHarmonics[9]
    // 我们只使用前两个波段以获得更好的性能
    return
          sphericalHarmonics[0]
        + sphericalHarmonics[1] * (n.y)
        + sphericalHarmonics[2] * (n.z)
        + sphericalHarmonics[3] * (n.x)
        + sphericalHarmonics[4] * (n.y * n.x)
        + sphericalHarmonics[5] * (n.y * n.z)
        + sphericalHarmonics[6] * (3.0 * n.z * n.z - 1.0)
        + sphericalHarmonics[7] * (n.z * n.x)
        + sphericalHarmonics[8] * (n.x * n.x - n.y * n.y);
}
```

注意, 使用2个波段时, 上面的计算变为 4×4 矩阵与向量的乘法.

另外, 由于使用 Kml 进行了预缩放, SH系数可视为颜色, 特别地`sphericalHarmonics[0]`直接就是平均辐照度.

#### 5.3.4.2 高光BRDF积分

 IBL的辐照度和BRDF之间的相互作用产生的辐射 Lout 为:

$L_{out}(n,v,Θ)=∫_Ωf(l,v,Θ)L_⊥(l)⟨n⋅l⟩∂l$(77)

f(l,v,Θ)⟨n⋅l⟩ 对 L⊥ 的卷积, 即, 使用BRDF作为核对环境进行 *过滤*. . 事实上, 粗糙度较高时, 镜面反射看起来更 *模糊*.

将 ff表达式代入方程77, 得到:

$L_{out}(n,v,Θ)=∫_ΩD(l,v,α)F(l,v,f_0,f_{90})V(l,v,α)⟨n⋅l⟩L_⊥(l)∂l$(78)

##### 5.3.4.2.1 简化BRDF积分

由于没有封闭形式的解或计算 Lout 积分的简单方法, 使用一个简化的方程: I^I^,假定 v=n, 即视线方向 v 始终等于表面法向 n. 

假定使得卷积的所有效果都与视线无关, 比如更接近观察者的反射模糊会增加(也称为拉伸反射).



简化也会对恒定环境产生严重影响, 因为它会影响结果的常数项的大小(即DC). 通过在简化积分中使用一个比例因子 K, 至少可以校正这一点, 可以确保如果选择的值合适, 得到的平均辐照度仍然正确

- I 为原始积分, 即:$ I(g)=∫_Ωg(l)⟨n⋅l⟩∂l$
- I^I^ 为简化积分, 其中 v=n
- K 为比例因子, 确保平均辐照度不被 I^I^ 改变
- I~I~ 为 I 的最终近似值, I~=I^×K

I 是一个积分乘积, 所以可以进行分解. 即: I(g()f())=I(g())I(f())

$I(f(Θ)L_⊥)≈\tilde{I}(f(Θ)L_⊥)\\ \tilde{I} (f(Θ)L_⊥)=K× \hat{I} (f(Θ)L_⊥)\\K=\frac{I(f(Θ))}{\hat{I}(f(Θ))}$(79)

当 L⊥ 为常量时, I~I~ 等价于 I, 由此得到正确的结果:

$$\tilde{I}(f(\Theta)L_⊥^\text{constant}) &= L_⊥^\text{constant} \hat{I}(f(\Theta)) \frac{I(f(\Theta))}{\hat{I}(f(\Theta))} \\&= L_⊥^\text{constant} I(f(\Theta))\\&= I(f(\Theta)L_⊥^\text{constant})$$

同样, 也可以证明, 当 v=n 时结果正确, 因为在这种情况下 I=I^:

$$\tilde{I}(f(\Theta)L_⊥) &= I(f(\Theta)L_⊥) \frac{I(f(\Theta))}{I(f(\Theta))}    \\ &= I(f(\Theta)L_⊥)$$

最后, 通过将 L⊥=L⊥¯+(L⊥−L⊥¯)=L⊥¯+ΔL⊥代入I~I~, 可以证明比例因子 K 满足平均辐照度(L⊥¯)要求.

$$\tilde{I}(f(\Theta) L_⊥) &= \tilde{I}\left[f\left(\Theta\right) \left(\bar{L_⊥} + \Delta L_⊥\right)\right] \\&= K \times \hat{I}\left[f\left(\Theta\right) \left(\bar{L_⊥} + \Delta L_⊥\right)\right] \\&= K \times \left[\hat{I}\left(f\left(\Theta\right)\bar{L_⊥}\right) + \hat{I}\left(f\left(\Theta\right)\Delta L_⊥\right)\right] \\&= K \times \hat{I}\left(f\left(\Theta\right)\bar{L_⊥}\right) + K \times \hat{I}\left(f\left(\Theta\right) \Delta L_⊥\right) \\&= \tilde{I}\left(f\left(\Theta\right)\bar{L_⊥}\right) + \tilde{I}\left(f\left(\Theta\right) \Delta L_⊥\right) \\&= I\left(f\left(\Theta\right)\bar{L_⊥}\right) + \tilde{I}\left(f\left(\Theta\right) \Delta L_⊥\right)$$

上述结果表明, 平均辐照度的计算正确, 即: $I(f(Θ)L_⊥^¯)$.

考虑这种近似的一种方法是, 它将辐照度 L⊥ 分成两部分, 平均 L⊥¯和来自平均的 ΔL⊥, 然后正确地计算平均部分的积分, 再加上delta部分的简化积分:

$$approximation(L_⊥)=correct(L_⊥^¯)+simplified(L_⊥−L_⊥^¯)$$(80)



$$\hat{I}(f(n, \alpha) L_⊥) = \int_\Omega f(l, n, \alpha) L_⊥(l) \left< n\cdot l \right> \partial l   \\\hat{I}(f(n, \alpha))     = \int_\Omega f(l, n, \alpha)        \left< n\cdot l\right> \partial l   \\I(f(n, v, \alpha))        = \int_\Omega f(l, n, v, \alpha)     \left< n\cdot l \right> \partial l$$

所有这三个方程都可以很容易地预先计算好并存储在查找表中

##### 5.3.4.2.2 离散域

在离散域中, [81 中的方程变为:

$$\hat{I}(f(n, \alpha)  L_⊥) \equiv \frac{1}{N}\sum_{\forall \, i \in image} f(l_i, n, \alpha)  L_⊥(l_i) \left< n\cdot l\right>  \\\hat{I}(f(n, \alpha))     \equiv \frac{1}{N}\sum_{\forall \, i \in image} f(l_i, n, \alpha)          \left< n\cdot l\right>  \\I(f(n, v, \alpha))        \equiv \frac{1}{N}\sum_{\forall \, i \in image} f(l_i, n, v, \alpha)       \left< n\cdot l\right>$$(82)

然而, 在实践中, 使用 *重要性抽样*, 需要考虑分布的 pdf, 并添加一项 $\frac{⟨v⋅h⟩}{D(hi,α)⟨n⋅h⟩}$.

$$\hat{I}(f(n, \alpha)  L_⊥) \equiv \frac{4}{N}\sum_i^N f(l_i, n, \alpha)    \frac{\left< v\cdot h\right>}{D(h_i, \alpha)\left< n\cdot h\right>}  L_⊥(l_i) \left< n\cdot l\right>  \\\hat{I}(f(n, \alpha))     \equiv \frac{4}{N}\sum_i^N f(l_i, n, \alpha)    \frac{\left< v\cdot h\right>}{D(h_i, \alpha)\left< n\cdot h\right>}          \left< n\cdot l\right>  \\I(f(n, v, \alpha))        \equiv \frac{4}{N}\sum_i^N f(l_i, n, v, \alpha) \frac{\left< v\cdot h\right>}{D(h_i, \alpha)\left< n\cdot h\right>}          \left< n\cdot l\right>$$(83)

回顾对于 I^I^, 我们假定 v=n, 方程 [83 简化为:

$$\hat{I}(f(n, \alpha)  L_⊥) \equiv \frac{4}{N}\sum_i^N \frac{f(l_i, n,    \alpha)}{D(h_i, \alpha)}  L_⊥(l_i) \left< n\cdot l\right>  \\\hat{I}(f(n, \alpha))     \equiv \frac{4}{N}\sum_i^N \frac{f(l_i, n,    \alpha)}{D(h_i, \alpha)}          \left< n\cdot l\right>  \\I(f(n, v, \alpha))        \equiv \frac{4}{N}\sum_i^N \frac{f(l_i, n, v, \alpha)}{D(h_i, \alpha)} \frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right>$$(84)

然后, 可以将前两个方程合并, 得到$$LD(n,α)=\frac{\hat{I}(f(n,α)L_⊥)}{\hat{I}(f(n,α))}$$

$$LD(n, \alpha)       \equiv \frac{\sum_i^N \frac{f(l_i, n, \alpha)}{D(h_i, \alpha)}  L_⊥(l_i) \left< n\cdot l\right>}{\sum_i^N \frac{f(l_i, n, \alpha)}{D(h_i, \alpha)}\left< n\cdot l\right>}$$(85)

$$I(f(n, v, \alpha))  \equiv \frac{4}{N}\sum_i^N \frac{f(l_i, n, v, \alpha)}{D(h_i, \alpha)} \frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right>$$(86)

请注意, 到这里, 几乎可以离线计算两个剩下的方程. 

唯一的困难在于, 当预先计算这些积分时, 我们不知道 f0 或 f90. 

在后面我们会看到, 我们可以在运行时将这些项合并到方程86, 可惜, 对方程 85 无法这样做, 我们必须假定 f0=f90=1 (即: Fresnel项的值总是1).

还必须处理BRDF的可见度项, 在实践中, 保留它得到的结果与实际情况相比略有降低, 所以我们也假定 V=1.



替换方程85 和 86 中的 f:

$$f(l_i, n, \alpha) = D(h_i, \alpha)F(f_0, f_{90}, \left< v\cdot h\right>)V(l_i, v, \alpha)$$(87)

第一个简化是, BRDF中的 D(hi,α) 与分母(来自重要性抽样的 pdf)相抵消, F 和 V 消失,

$$LD(n, \alpha)       \equiv \frac{\sum_i^N V(l_i, v, \alpha)\left< n\cdot l\right> L_⊥(l_i) }{\sum_i^N \left< n\cdot l\right>}$$(88)

$$I(f(n, v, \alpha))  \equiv \frac{4}{N}\sum_i^N \color{green}{F(f_0, f_{90}, \left< v\cdot h\right>)} V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right>$$(89)

将Fresnel项代入方程 89:

$$F(f_0, f_{90}, \left< v\cdot h\right>) = f_0 (1 - F_c(\left< v\cdot h\right>)) + f_{90} F_c(\left< v\cdot h\right>) \\F_c(\left< v\cdot h\right>) = (1 - \left< v\cdot h\right>)^5$$(90)

$$I(f(n, v, \alpha))  \equiv \frac{4}{N}\sum_i^N \left[\color{green}{f_0 (1 - F_c(\left< v\cdot h\right>)) + f_{90} F_c(\left< v\cdot h\right>)}\right] V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right> \\$$(91)

最后, 我们提取可以离线计算的方程(即: 不依赖于运行时参数 f0 和 f90 的部分):

$$I(f(n, v, \alpha))  \equiv \frac{4}{N}\sum_i^N \left[\color{green}{f_0 (1 - F_c(\left< v\cdot h\right>)) + f_{90} F_c(\left< v\cdot h\right>)}\right] V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right> \\I(f(n, v, \alpha)) \equiv \color{green}{f_0   } \frac{4}{N}\sum_i^N  \color{green}{(1 - F_c(\left< v\cdot h\right>))} V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right> \\ \+\color{green}{f_{90}} \frac{4}{N}\sum_i^N  \color{green}{     F_c(\left< v\cdot h\right>) } V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right>$$(92)

请注意, DFG1 和 DFG2 仅取决于 n⋅v, 即法向 n 和视线方向 v 之间的夹角. 这是正确的, 因为积分关于 n 对称. 进行积分时, 可以选择任何 v, 只要它满足 n⋅v

将所有结果重新组合在一起, 得到:

*Important*

$$L_{out}(n,v,\alpha,f_0,f_{90})     &\simeq \big[ f_0 \color{red}{DFG_1( n\cdot v, \alpha)} + f_{90} \color{red}{DFG_2( n\cdot v, \alpha)} \big] \times LD(n, \alpha) \\DFG_1(\alpha, \left< n\cdot v\right>) &=      \frac{4}{N}\sum_i^N  \color{green}{(1 - F_c(\left< v\cdot h\right>))} V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right> \\DFG_2(\alpha, \left< n\cdot v\right>) &=      \frac{4}{N}\sum_i^N  \color{green}{     F_c(\left< v\cdot h\right>) } V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left< n\cdot l\right> \\LD(n, \alpha)                    &=      \frac{\sum_i^N V(l_i, n, \alpha)\left< n\cdot l\right> L_⊥(l_i) }{\sum_i^N \left< n\cdot l\right>}$$



#### 5.3.4.3 DFG1 和 DFG2 项的可视化

DFG1 和 DFG2 项既可以在常规2D纹理中预先计算并使用 (n⋅v,α) 作为索引进行双线性采样,也可以在运行时使用表面的解析近似进行计算. 

| DFG1DFG1                                                     | DFG2DFG2                                                     | DFG1,DFG2,0DFG1,DFG2,0                                       |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg1.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg1.png) | [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg2.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg2.png) | [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg.png) |

**表 15:** Y轴: αα. X轴: cosθ

DFG1 和 DFG2 处于方便的 [0,1][0,1] 范围内, 但是8位的纹理没有足够的精度, 并且会引起问题. 不幸的是, 在移动设备上, 16位或浮点纹理并不普遍, 而且采样器数量也有限. 尽管使用纹理的着色器代码非常简单, 有吸引力, 但使用解析近似可能更好. 但请注意, 由于我们只需要存储两项, OpenGL ES 3.0的RG16F纹理格式是一个很好的选择.



解析近似见[[Karis14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-karis14)], 其本身基于[[Lazarov13](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-lazarov13)]. [[Narkowicz14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-narkowicz14)]是另一个有趣的近似. 

请注意, 这两个近似与节 [5.3.4.7](https://jerkwin.github.io/filamentcn/Filament.md.html#toc5.3.4.7)中介绍的能量补偿项不兼容. [表 16](https://jerkwin.github.io/filamentcn/Filament.md.html#表_textureapproxdfg)给出了这些近似的直观表示.

| DFG1DFG1                                                     | DFG2DFG2                                                     | DFG1,DFG2,0DFG1,DFG2,0                                       |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg1_approx.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg1_approx.png) | [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg2_approx.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg2_approx.png) | [![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg_approx.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg_approx.png) |

**表 16:** Y轴: αα. X轴: cosθ

#### 5.3.4.4 LD 项的可视化

LD 为一个函数对环境的卷积, 此函数只取决于 α 参数;LD 可以方便地存储在mip映射的立方体贴图中, 其中增加的LOD接收使用增大的粗糙度进行预先过滤的环境. 

为了充分利用每个mipmap级别, 有必要重新映射 α; 我们发现使用 γ=2 的幂函数重新映射效果很好并且很方便.

$$α=perceptualRoughness^2\\lodα=α^{1/2}=perceptualRoughness$$



#### 5.3.4.5 间接镜面反射分量和间接漫反射分量的可视化

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_visualization.jpg)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_visualization.jpg)

**图 54:** 间接漫反射和镜面反射的分解

#### 5.3.4.6 IBL计算的实现

```glsl
vec3 ibl(vec3 n, vec3 v, vec3 diffuseColor, vec3 f0, vec3 f90, float perceptualRoughness) {
    vec3 r = reflect(n);
    vec3 Ld = textureCube(irradianceEnvMap, r) * diffuseColor;
    vec3 Lld = textureCube(prefilteredEnvMap, r, computeLODFromRoughness(perceptualRoughness));
    vec2 Ldfg = textureLod(dfgLut, vec2(dot(n, v), perceptualRoughness), 0.0).xy;
    vec3 Lr =  (f0 * Ldfg.x + f90 * Ldfg.y) * Lld;
    return Ld + Lr;
}
```

可以通过使用球谐函数而不是辐照度立方贴图, 以及 DFG LUT的解析近似来保存几个纹理查找表

```glsl
vec3 irradianceSH(vec3 n) {
    // uniform vec3 sphericalHarmonics[9]
    // 我们只使用前两个波段以获得更好的性能
    return
          sphericalHarmonics[0]
        + sphericalHarmonics[1] * (n.y)
        + sphericalHarmonics[2] * (n.z)
        + sphericalHarmonics[3] * (n.x)
        + sphericalHarmonics[4] * (n.y * n.x)
        + sphericalHarmonics[5] * (n.y * n.z)
        + sphericalHarmonics[6] * (3.0 * n.z * n.z - 1.0)
        + sphericalHarmonics[7] * (n.z * n.x)
        + sphericalHarmonics[8] * (n.x * n.x - n.y * n.y);
}

// 注意: 如果使用了多重散射的能量补偿项此近似无效// 我们使用DFG LUT分辨率来实现多重散射
vec2 prefilteredDFG(float NoV, float perceptualRoughness) {
    // 基于Lazarov的Karis逼近
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);
    vec4 r = perceptualRoughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
    // 基于Karis的Zioma逼近
    // return vec2(1.0, pow(1.0 - max(perceptualRoughness, NoV), 3.0));
}

// 注意: 这是上面函数的DFG LUT实现
vec2 prefilteredDFG_LUT(float coord, float NoV) {
    // coord = sqrt(roughness)
    // 计算mipmap时IBL预过滤代码使用的贴图
    return textureLod(dfgLut, vec2(NoV, coord), 0.0).rg;
}

vec3 evaluateSpecularIBL(vec3 r, float perceptualRoughness) {
    // 假定为256x256的立方体贴图, 有9个mip级别
    float lod = 8.0 * perceptualRoughness;
    // decodeEnvironmentMap() 用于解码RGBM,
    // 或者no-op, 如果立方体贴图存储在浮点纹理中
    return decodeEnvironmentMap(textureCubeLodEXT(environmentMap, r, lod));
}

vec3 evaluateIBL(vec3 n, vec3 v, vec3 diffuseColor, vec3 f0, vec3 f90, float perceptualRoughness) {
    float NoV = max(dot(n, v), 0.0);
    vec3 r = reflect(-v, n);

    // 间接镜面
    vec3 indirectSpecular = evaluateSpecularIBL(r, perceptualRoughness);
    vec2 env = prefilteredDFG_LUT(perceptualRoughness, NoV);
    vec3 specularColor = f0 * env.x + f90 * env.y;

    // 间接漫反射
    // 乘以Lambertian BRDF来计算辐射的辐照度
    // 对于迪斯尼BRDF, 我们必须删除Fresnel项
    // 它取决于NoL(它会放到SH中). Lambertian BRDF
    // 可以直接在SH中烘焙以节省这里的乘法
    vec3 indirectDiffuse = max(irradianceSH(n), 0.0) * Fd_Lambert();

    // 间接贡献
    return diffuseColor * indirectDiffuse + indirectSpecular * specularColor;
}
```

#### 5.3.4.7 多重散射的预积分

使用第二个缩放的镜面波瓣来补偿由于只考虑BRDF中的单重散射事件而导致的能量损失. 这个能量补偿波瓣使用的缩放项取决于 r, 其定义如下:

$r=∫_ΩD(l,v)V(l,v)⟨n⋅l⟩∂l$(93)

或者, 使用重要性抽样进行计算

$r≡\frac{4}{N}∑_i^NV(l_i,v,α)\frac{⟨v⋅h⟩}{⟨n⋅h⟩}⟨n⋅l⟩$(94)

非常类似于方程 92 中的 DFG1和 DFG2.事实上, 除没有Fresnel项外, 它们是一样的.

通过进一步假定 f90=1, 可以重写 DFG1 和 DFG2以及 Lout 的重建:

$$L_{out}(n,v,\alpha,f_0)\simeq \big[ (1 - f_0) \color{red}{DFG_1^{\text{multiscatter}}( n\cdot v, \alpha)} \\+ f_0 \color{red}{DFG_2^{\text{multiscatter}}( n\cdot v, \alpha)} \big] \\ \times LD(n, \alpha) $$

$$DFG_1^{\text{multiscatter}}(\alpha, \left< n\cdot v\right>)=\frac{4}{N}\sum_i^N  \color{green}{F_c(\left< v\cdot h\right>)} \\V(l_i, v, \alpha)\frac{\left< v\cdot h\right>}{\left< n\cdot h\right>} \left<n⋅l\right> $$

$$DFG_2^{\text{multiscatter}}(\alpha, \left< n\cdot v\right>)=\frac{4}{N}\sum_i^N V(l_i,v,α)\frac{⟨v⋅h⟩}{⟨n⋅h⟩}⟨n⋅l⟩$$

$$LD(n, \alpha)=\frac{\sum_i^N V(l_i, n, \alpha)\left<n⋅l\right>L_⊥(l_i) }{\sum_i^N V(l_i, n, \alpha)\left<n⋅l\right>}$$



简单地用这两个新的 DFG项替换节 [9.5]给出的实现中所用的项即可:

```
float Fc = pow(1 - VoH, 5.0f);
r.x += Gv * Fc;
r.y += Gv;
```

**清单 29:** 多重散射 LDFG 项的C++实现

```
vec2 dfg = textureLod(dfgLut, vec2(dot(n, v), perceptualRoughness), 0.0).xy;
// (1 - f0) * dfg.x + f0 * dfg.y
vec3 specularColor = mix(dfg.xxx, dfg.yyy, f0);
```

**清单 30:** 基于图像的光照计算的GLSL实现, 使用了多重散射LUT

#### 5.3.4.8 总结

为计算远程的基于图像的灯光的镜面反射贡献,不得不做出一些近似和折衷:

- **v=n**, 到目前为止,在积分IBL的非常数部分时, 此假定引入的误差最大. 这导致与视点的粗糙度有关的各向异性 完全丧失.
- IBL非常数部分的粗糙度贡献被离散分级, 并使用三线性滤波在不同级别之间进行插值. 这在低粗糙度时最为明显(例如: 对一个9 LOD的立方体贴图约为0.0625).
- 由于使用mipmap级别存储预积分的环境, 因此它们无法用于纹理缩小, 而这是它们应该做的. 这可能导致高频区域, 低粗糙度环境, 遥远或较小的物体会出现锯齿或莫尔条纹. 由于缓存访问模式不佳, 这也会影响性能.
- IBL的非常数部分**没有Fresnel项.**
- IBL非常数部分的**可见度**=1.
- Schlick的Fresnel项
- 多重散射情况下 f90=1

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_prefilter_vs_reference.png)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_prefilter_vs_reference.png)

**图 55:** 重要性采样参考(上)和预滤波IBL(中)之间的比较.

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_stretchy_reflections_error.png)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_stretchy_reflections_error.png)

**图 56:** 假定 v=n 引起的反射错误(下) - "弹性反射"丢失.

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_trilinear_0.png)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_trilinear_0.png)

**图 57:** 由于在粗糙度 = 0.0625的立方体贴图LOD中存储粗糙度而导致的错误(即: 在各级之间精确采样). 请注意, 我们看到的不是模糊, 而是两个模糊之间的"交叉阴纹".

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_trilinear_1.png)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_trilinear_1.png)

**图 58:** 由于在粗糙度 = 0.125的立方体贴图LOD中存储粗糙度而导致的错误(即: 在1级精确采样). 当粗糙度与LOD非常匹配时, 在立方体贴图中进行三线性滤波引起的误差会减小. 注意由于 v=n 在掠射角处引起的误差.

[![img](https://jerkwin.github.io/filamentcn/images/ibl/ibl_no_mipmaping.png)](https://jerkwin.github.io/filamentcn/images/ibl/ibl_no_mipmaping.png)

**图 59:** 处于由彩色垂直条纹(隐藏了天空盒)组成的环境中, α=0 的金属球体上由于纹理缩小而形成的莫尔图案.

### 5.3.5 透明涂层

当对IBL进行采样时, 透明涂层作为第二镜面反射的波瓣来计算.  这个镜面波瓣的取向沿视线方向, 因为无法在半球上进行合理地积分. 

在实践中使用的这种近似. 它还给出了能量守恒步骤. 需要注意的是, 第二镜面波瓣的计算方式与主镜面波瓣完全相同, 使用了相同的DFG近似 .

```glsl
// clearCoat_NoV == shading_NoV 如果透明涂层没有自己的法线贴图
float Fc = F_Schlick(0.04, 1.0, clearCoat_NoV) * clearCoat;
// 基础层衰减的能量补偿
iblDiffuse  *= 1.0 - Fc;
iblSpecular *= sq(1.0 - Fc);
iblSpecular += specularIBL(r, clearCoatPerceptualRoughness) * Fc;
```

**清单 31:** 用于基于图像的光照的透明涂层镜面波瓣的GLSL实现

### 5.3.6 各向异性

[[McAuley15](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-mcauley15)]给出了一种称为"弯曲反射向量"的技术, 该技术基于[[Revie12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-revie12)]. 弯曲反射向量是各向异性光照的粗略近似, 但替代方案是使用重要性采样. 这种近似足够便宜, 并可以提供很好的结果

```glsl
vec3 anisotropicTangent = cross(bitangent, v);
vec3 anisotropicNormal = cross(anisotropicTangent, bitangent);
vec3 bentNormal = normalize(mix(n, anisotropicNormal, anisotropy));
vec3 r = reflect(-v, bentNormal);
```

**清单 32:** 弯曲反射向量的GLSL实现

通过接受负的"各向异性"值可以使这种技术变得更加有用,当各向异性为负值时, 高光不在切线方向上, 而是在副切线方向上.

```glsl
vec3 anisotropicDirection = anisotropy >= 0.0 ?bitangent : tangent;
vec3 anisotropicTangent = cross(anisotropicDirection, v);
vec3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
vec3 bentNormal = normalize(mix(n, anisotropicNormal, anisotropy));
vec3 r = reflect(-v, bentNormal);
```

**清单 33:** 弯曲反射向量的GLSL实现

### 5.3.7 次表面

TODO

### 5.3.8 布料

布料模型的IBL实现比其他材质模型更复杂.主要区别在于使用了不同的NDF(Charlie, 高度相关的Smith GGX). 

在计算IBL时, 我们使用拆分求和近似来计算BRDF的DFG项. 由于这个DFG项是设计用于不同的BRDF的, 因此不能用于布料BRDF. 

由于我们设计的布料BRDF不需要Fresnel项, 我们可以在DFG LUT的第三个通道中生成单个DG项.



生成DG项时使用了[[Estevez17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-estevez17)]推荐的均匀采样方法. 在这种情况下, pdf 为简单的 1/2π, 我们仍然必须使用Jacobian 1/4⟨v⋅h⟩.

[![img](https://jerkwin.github.io/filamentcn/images/ibl/dfg_cloth.png)](https://jerkwin.github.io/filamentcn/images/ibl/dfg_cloth.png)

**图 63:** DFG LUT的第三个通道编码了布料BRDF的DG项

基于图像的光照的实现的其余部分与常规光照的实现步骤相同, 包括可选的次表面散射项及其包裹漫反射分量. 正如透明涂层IBL实现一样, 不能在半球上进行积分, 使用视线方向作为主要光照方向来计算包裹漫反射分量.

```glsl
float diffuse = Fd_Lambert() * ambientOcclusion;
#if defined(SHADING_MODEL_CLOTH)
#if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
diffuse *= saturate((NoV + 0.5) / 2.25);
#endif
#endif

vec3 indirectDiffuse = irradianceIBL(n) * diffuse;
#if defined(SHADING_MODEL_CLOTH) && defined(MATERIAL_HAS_SUBSURFACE_COLOR)
indirectDiffuse *= saturate(subsurfaceColor + NoV);
#endif

vec3 ibl = diffuseColor * indirectDiffuse + indirectSpecular * specularColor;
```

**清单 36:** 布料NDF的DFG近似的GLSL实现

需要注意的是, 这只解决了部分IBL问题. 前面描述了预过滤镜面反射环境贴图与标准着色模型的BRDF卷积, 后者与布料BRDF不同. 为获得准确的结果, 理论上我们应该在渲染引擎中为每个BRDF提供一组IBL. 然而, 提供第二组IBL对于我们的使用情景来说是不实际的, 因此我们决定依赖现有的IBL.



## 5.4 静态光照

TODO

球谐函数或球高斯光照贴图, 辐照度体积, PRT

## 5.5  透明度和半透明光照

要正确地对透明表面进行光照, 我们首先必须了解如何应用材质的不透明度. 观察一个窗口, 你会发现漫反射是透明的. 另一方面, 镜面反射越亮, 窗口呈现的不透明度越低. 



### 5.5.1 透明度

为正确地实现不透明度, 使用预乘的alpha格式. 给定所需的不透明度 αopacity, 漫反射颜色 σ (线性, 未预乘), 可以计算面片的有效不透明度.

$$color=σ*α_{opacity}\\opacity=α_{opacity}$$

物理解释是, 来源颜色的RGB分量定义像素发射多少光, 而alpha分量定义像素背后有多少光被遮挡. 

混合函数:

$$Blend_{src}=1\\Blend_{dst}=1-src_α$$

```
// baseColor已经预先乘过
vec4 shadeSurface(vec4 baseColor) {
    float alpha = baseColor.a;

    vec3 diffuseColor = evaluateDiffuseLighting();
    vec3 specularColor = evaluateSpecularLighting();

    return vec4(diffuseColor + specularColor, alpha);
}
```

**清单 37:** 被照亮表面透明度的GLSL实现

### 5.5.2 半透明 

半透明材质可分为两类:

- 表面半透明
- 体积半透明

体积半透明对于粒子系统的光照非常有用, 例如云或烟雾. 表面半透明可用于模拟具有透射散射的材料, 如蜡, 大理石, 皮肤等.

[TODO]表面半透明度(BRDF+BTDF, BSSRDF)

## 5.6 遮蔽 

遮蔽是一个重要的暗化因素, 用于在各种尺度下重建阴影:

小尺度: 微遮蔽, 用于处理折痕, 裂缝和空洞

中等尺度: 宏遮蔽, 用于处理物体自身几何遮蔽或法线贴图(砖块等)中烘焙几何体的遮蔽.

大尺度: 遮蔽来自物体之间的接触, 或来自物体自身的几何.

目前忽略了微遮蔽, 工具和引擎通常以"孔洞贴图"的形式提供它. 

Sébastien Lagarde在[[Lagarde14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-lagarde14)]中提供了关于如何在Frostbite引擎中处理微遮蔽的有趣讨论: 在漫反射贴图中预先烘焙漫反射微遮蔽, 并在反射纹理中预先烘焙镜面微遮蔽. 

在我们的系统中, 微遮蔽可以简单地在基色图中烘焙. 这必须在知道镜面光不受微遮蔽的影响情况下才可以.

中等尺度的环境遮蔽在环境遮蔽贴图中预烘焙, 并作为材质参数提供

大尺度的环境光遮蔽通常使用屏幕空间技术来计算;请注意, 当相机足够接近表面时, 这些技术也可用于中等尺度的环境遮蔽.

**注意**: 为了防止在使用中等和大尺度遮蔽时过度变暗, Lagarde建议使用 min(AOmedium,AOlarge)

### 5.6.1 漫反射遮蔽 

在[[McGuire10](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-mcguire10)]中, Morgan McGuire在基于物理的渲染的情境下对环境遮蔽进行了形式化. 在他的表述中, McGuire定义了一个环境光照函数 La, 在我们的例子中, 这个函数是用球谐函数编码的. 他还定义了一个可见度函数 V , 如果在 ll 方向上有一条来自表面的视线未被遮蔽, 则 V(l)=1, 否则为0.

利用这两个函数, 渲染方程的环境项可以表示为方程 95.

$L(l,v)=∫_Ωf(l,v)L_a(l)V(l)⟨n⋅l⟩dl$(95)

可以通过将可见度项与光照函数分开来近似此表达式, 如方程 96 所示.

$L(l,v)≈(π∫_Ωf(l,v)L_a(l)dl)(\frac{1}{π}∫_ΩV(l)⟨n⋅l⟩dl)$(96)

只有当远程光 La 不变且 f 为Lambertian项时, 这种近似才是精确的. 然而, McGuire指出, 如果两个函数在球体的大部分上相对平滑, 则这种近似是合理的. 这恰好是平行光探头(IBL)的情况.

此近似的左侧项是IBL预计算的漫反射分量. 右侧项是介于0和1之间的标量因子, 表示一个点的可及性比例. 其相反数就是漫反射的环境遮蔽项, 如方程 97 所示.

$AO=1−1π∫_ΩV(l)⟨n⋅l⟩dl$(97)

由于使用预先计算的漫反射项, 因此无法在运行时计算着色点的精确可及性. 为了弥补预计算项中缺少的信息, 通过在着色点应用特定于表面材质的环境遮蔽因子来部分重建入射光.

在实践中, 烘焙的环境遮蔽作为灰度纹理存储, 其分辨率常常比其他纹理(例如基色或法线)更低. 值得注意的是, 我们的材质模型的环境遮蔽性质旨在重建宏观水平的漫反射环境遮蔽. 虽然这种近似在物理上是不正确的, 但它在质量与性能之间达到了可接受的折衷.

```
// 间接漫反射
vec3 indirectDiffuse = max(irradianceSH(n), 0.0) * Fd_Lambert();
// 环境遮蔽
indirectDiffuse *= texture2D(aoMap, outUV).r;
```

**清单 38:** 烘焙的漫反射环境遮蔽的GLSL实现

请注意环境遮蔽项仅适用于间接光照.

### 5.6.2 镜面遮蔽 

镜面微遮蔽可以从 f0 导出, 它本身来自漫反射颜色. 推导基于以下知识: 真实世界的材料具有的反射率不会低于2%. 因此, 可以将0-2%范围内的值视为预烘焙的镜面遮蔽, 用于平滑地消除Fresnel项.

```
float f90 = clamp(dot(f0, 50.0 * 0.33), 0.0, 1.0);
// 便宜的亮度近似
float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
```

**清单 39:** 预烘焙镜面遮蔽的GLSL实现

前面提到的环境遮蔽的推导假定为Lambertian表面, 并且只适用于间接漫反射光照. 缺乏表面可及性信息对间接镜面光照的重建特别有害. 它通常表现为光线泄漏.

Sébastien Lagarde在[[Lagarde14](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-lagarde14)]中提出了一种经验方法, 可以从漫反射遮蔽项推导出镜面遮蔽项. 方法没有任何物理基础, 但得到的结果在视觉上令人满意. 他的公式的目标是返回粗糙表面的未修改的漫反射遮蔽项. 对于光滑表面, 清单 40中实现的公式减少了垂直入射时遮蔽的影响, 并增加了掠射角处的遮蔽影响.

Important

```
float computeSpecularAO(float NoV, float ao, float roughness) {
    return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

// 间接镜面
vec3 indirectSpecular = evaluateSpecularIBL(r, perceptualRoughness);
// 环境光遮蔽
float ao = texture2D(aoMap, outUV).r;
indirectSpecular *= computeSpecularAO(NoV, ao, roughness);
```

**清单 40:** Lagarde镜面遮蔽因子的GLSL实现

请注意镜面遮蔽因子只用于间接光照.

#### 5.6.2.1 水平镜面遮蔽

当计算使用法线贴图的表面的镜面IBL贡献时, 可能最终得到一个指向表面的反射向量. 如果此反射向量直接用于着色, 则表面上不应照亮的位置会被照亮(假设表面不透明). 这是另一种光泄漏现象, 可以使用Jeff Russell给出的简单技术轻松地将其影响最小化[[Russell15](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-russell15)].

关键的思想是遮蔽来自表面后面的光. 这很容易实现, 因为反射向量和表面法线之间的负点积表示指向表面的反射向量. [清单 41]中展示的实现类似于Russell的, 虽然没有使用美工可以控制的地平线衰减因子.

```
// 间接镜面
vec3 indirectSpecular = evaluateSpecularIBL(r, perceptualRoughness);

// 带衰减的水平遮蔽, 直接镜面也应该计算
float horizon = min(1.0 + dot(r, n), 1.0);
indirectSpecular *= horizon * horizon;
```

**清单 41:** 水平高光遮蔽的GLSL实现

水平镜面遮蔽衰减很便宜, 但很容易根据需要省略它以提高性能.



## 5.7 法线贴图

用低多边形网格替换高多边形网格(使用基础贴图), 添加表面细节(使用细节贴图).

鉴于法线贴图的性质(XYZ分量存储在切线空间中), 很显然, 诸如线性或叠加混合等简单方法无法使用. 我们将使用两种更先进的技术: 一种是数学上正确的技术, 另一种是适用于实时着色的近似技术.

### 5.7.1 重定向法线贴图

Colin Barré-Brisebois和Stephen Hill在[[Hill12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-hill12)]

它包括将细节图的基旋转到基本贴图的法线上. 这种技术使用最短弧四元数来施加旋转, 借助切线空间的性质, 可大大简化了旋转.

```
vec3 t = texture(baseMap,   uv).xyz * vec3( 2.0,  2.0, 2.0) + vec3(-1.0, -1.0,  0.0);
vec3 u = texture(detailMap, uv).xyz * vec3(-2.0, -2.0, 2.0) + vec3( 1.0,  1.0, -1.0);
vec3 r = normalize(t * dot(t, u) - u * t.z);
return r;
```

**清单 42:** 重定向法线贴图的GLSL实现

请注意, 此实现假定法线存储时未压缩, 并且在源纹理中处于[0..1]范围内.

归一化步骤并不是严格必需的, 如果在运行时使用该技术, 可以忽略. 如果这样, `r`的计算变为`t * dot(t, u) / t.z - u`.

由于这种技术比下面描述的技术略贵一些, 我们将主要离线使用它. 



### 5.7.2 UDN混合

[[Hill12](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-hill12)]中描述技术称为UDN混合, 它是偏导数混合技术的一种变体. 它的主要优点是需要的着色器指令数量较少(参见[清单 43](https://jerkwin.github.io/filamentcn/Filament.md.html#清单_udnblending)). 

. 虽然它可以减少平面区域的细节, 但如果运行时必须要进行混合, 那UDN混合很有意义.

```
vec3 t = texture(baseMap,   uv).xyz * 2.0 - 1.0;
vec3 u = texture(detailMap, uv).xyz * 2.0 - 1.0;
vec3 r = normalize(t.xy + u.xy, t.z);
return r;
```

**清单 43:** UDN混合的GLSL实现

得到的结果在视觉上接近重定向法线贴图, 但对数据进行的仔细比较表明UDN确实不太正确.



# 6 体积效应

### 6.1 指数高度雾



## 7 抗锯齿

TODO

MSAA 

Geometric AA 几何AA(法线和粗糙度)

着色器抗锯齿(物体空间着色G-buffer AA

## 8 成像管道

光照部分描述了光线如何以物理的方式与场景中的表面相互作用. 为获得合理的结果, 我们必须更进一步, 考虑将根据光照方程计算的场景亮度转换为可显示的像素值时所需要的变换.

我们将要使用的一系列转换形成以下成像管道:



[![img](https://jerkwin.github.io/filamentcn/images/pipe.png)](https://jerkwin.github.io/filamentcn/images/pipe.png)

**图 77:** 成像管道

**注意**: *OETF*步骤是应用目标色彩空间的光电传递函数. 

色彩空间(ACES, sRGB, Rec. 709, Rec. 2020等), 伽马/线性等



### 8.1 基于物理的相机

#### 8.1.1 曝光设置

#### 8.1.2 曝光值

##### 8.1.2.1 曝光值和亮度

##### 8.1.2.2 曝光值和照度

##### 8.1.2.3 曝光补偿

#### 8.1.3 曝光

#### 8.1.4 自动曝光

##### 8.1.4.1 光斑测量

##### 8.1.4.2 中心加权测量

##### 8.1.4.3 适应

#### 8.1.5 泛光



### 8.2 光学后处理

#### 8.2.1 彩色边纹

#### 8.2.2 镜头光晕

基于物理的方法来生成镜头光晕, 方法是对穿过镜头光学组的光线进行追踪, 但我们将使用基于图像的方法. 

### 8.3 影片后处理

#### 8.3.1 对比度

#### 8.3.2 曲线

#### 8.3.3 级别

#### 8.3.4 颜色分级

### 8.4 光路

引擎使用的光路或渲染方法可能会严重影响性能, 并且可能大大限制场景中可使用的灯光数目. 传统上, 3D引擎使用两种不同的渲染方法: 正向渲染和延迟渲染.

目标是使用符合以下约束的渲染方法:

- 低带宽要求
- 每个像素多个动态灯光

希望能够轻松支持:

- MSAA
- 透明
- 多材质模型

许多现代3D渲染引擎使用延迟渲染, 可以轻松支持数十, 数百甚至数千种灯光(以及其他优点). 遗憾的是, 这种方法在带宽方面非常昂贵. 使用我们的默认PBR材质模型, G缓冲区每像素使用160到192位, 这将直接导致相当高的带宽要求.



另一方面, 正向渲染方法向来不擅长处理多个灯光. 常见的实现方法是多次渲染场景, 每次渲染一个可见光源, 然后再混合(累加)结果. 另一种方法是为场景中的每个物体指定固定的最大灯光数. 然而, 当物体占据世界中的大量空间时(建筑物, 道路等), 这是不切实际的.



分块着色可用于前向渲染和延迟渲染方法. 思想是将屏幕划分成一个图块网格, 对每个图块, 查找可以影响其内部像素的灯光的列表. 这种做法具有减少过度绘制(在延迟渲染中)和大型物体着色计算(在前向渲染中)的优点. 然而, 这种技术存在深度不连续性的问题, 可能导致大量无关的工作.



#### 8.4.1 聚类前向渲染

聚类着色,用它的前向变体形式. 聚类着色扩展了分块渲染的想法, 但在第3个轴上添加了分段. "聚类"是在视图空间中完成的, 方法是将视锥划分为三维网格.

首先在深度轴上对视锥进行切片,

[![img](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_slices.jpg)](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_slices.jpg)

**图 82:** 深度切片(16片)

然后将深度切片与屏幕图块组合起来, 对视锥进行"体素化"(Voxelize). 我们将每个簇称为锥素, 因为它清楚地表明了它们代表的是什么(视锥空间中的体素). 

[![img](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_froxels1.jpg)](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_froxels1.jpg)

**图 83:** 视锥体素化(5×3图块, 8个深度切片)

[![img](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_froxels2.jpg)](https://jerkwin.github.io/filamentcn/images/screenshot_sponza_froxels2.jpg)

**图 84:** 视锥体素化(5×3图块, 8个深度切片)

在渲染帧之前, 会将场景中的每个灯光指定给与其相交的所有锥素. 灯光指定通道的结果是每个锥素的灯光列表. 在渲染通道中, 我们可以计算片段所属的锥素的ID, 从而得到影响该片段的灯光列表.

深度切片不是线性的, 而是指数的. 在典型的场景中, 靠近近平面的像素多于远平面的. 因此, 锥素的指数网格可以改善最重要的灯光的分配.

[![img](https://jerkwin.github.io/filamentcn/images/diagram_froxels1.png)](https://jerkwin.github.io/filamentcn/images/diagram_froxels1.png)

**图 85:** 近: 0.1米, 远: 100米, 16片

遗憾的是, 简单的指数体素化是不够的. 上图清楚地说明了世界空间如何沿切片分布, 但它无法显示靠近近平面的情况. 如果我们在较小的范围(0.1 m到7 m)内检查相同的分布, 我们可以看到一个有趣的问题, 如[图 86](https://jerkwin.github.io/filamentcn/Filament.md.html#图_froxeldistributionclose)所示.

[![img](https://jerkwin.github.io/filamentcn/images/diagram_froxels2.png)](https://jerkwin.github.io/filamentcn/images/diagram_froxels2.png)

**图 86:** 0.1-7m范围内的深度分布

此图显示, 简单的指数分布使用了切片的一半, 这些切片与相机非常接近. 在这个特殊的例子中, 我们使用了前5米的16个切片中的8个. 由于动态世界灯光是点光源(球体)或聚光灯(锥体), 因此靠近近平面的分辨率完全不需要如此精细.

解决方案是根据场景, 近平面和远平面手动调整第一个锥素的大小. 通过这样做, 我们可以更好地将剩余锥素分布在整个视锥内. [图 87](https://jerkwin.github.io/filamentcn/Filament.md.html#图_froxeldistributionexp)展示了如果我们使用0.1 m到5 m之间的特殊锥素时会发生什么情况.

[![img](https://jerkwin.github.io/filamentcn/images/diagram_froxels3.png)](https://jerkwin.github.io/filamentcn/images/diagram_froxels3.png)

**图 87:** 近: 0.1, 远: 100米, 16片, 特殊锥素: 0.1-5米



这种新的分布更加高效, 并且可以在整个视锥中更好地分配灯光.



#### 8.4.2 实现说明

灯光指定可以通过两种不同的方式完成, 一种是在GPU上, 另一种是在CPU上.

##### 8.4.2.1 GPU灯光指定

这种实现需要OpenGL ES 3.1以及对计算着色器的支持. 灯光存储在着色器存储缓冲区对象(SSBO)中, 并传递给计算着色器, 着色器将每个灯光指定给相应的锥素.

视锥体素化只能由第一个计算着色器执行一次(只要投影矩阵不改变), 并且可以由另一个计算着色器对每帧执行灯光分配.

计算着色器的线程模型特别适合这种任务. 我们只需调用与锥素同样的工作组(我们可以直接将X, Y和Z工作组计数映射到我们的锥素网格分辨率). 每个工作区将依次进行并遍历要指定的所有灯光.

相交测试意味着简单的球体/视锥或锥体/视锥测试.

有关GPU实现的源代码, 请参阅附录(仅限于点光源).



##### 8.4.2.2 CPU灯光指定

在非OpenGL ES 3.1设备上, 可以在CPU上有效地执行灯光指定. 该算法与GPU实现不同. 引擎会将每个灯光"光栅化"为锥素, 而不是对每个锥素的每个灯光进行迭代. 

与GPU变体相比, 这种技术具有额外好处, 可以提供更严格的剔除. CPU实现还可以更轻松地生成一个打包的灯光列表.



##### 8.4.2.3 着色

每个锥素的灯光列表可以作为SSBO(OpenGL ES 3.1)或纹理传递给片段着色器.

##### 8.4.2.4 从深度到锥素

给定近平面 n, 远平面 f, 最大深度切片数 m 和[0..1]范围内的线性深度值 z, 方程 117 可用于计算给定位置的聚类索引.

$$zToCluster(z,n,f,m)=floor(max(log_2(z)\frac{m}{-log_2(\frac{n}{f})}+m,0))$$(117)

然而, 这一公式存在前面提到的分辨率问题. 可以通过引入 sn 来解决这个问题, 它是一个特殊的近似值, 用于定义第一个锥素的范围(第一锥素占据范围[n..sn], 其余的体素占据范围[sn..f]).

$$zToCluster(z,n,sn,f,m)=floor(max(log_2(z)\frac{m-1}{-log_2(\frac{sn}{f})}+m,0))$$(118)

方程 119 可用于从`gl_FragCoord.z`计算线性深度值(假定标准OpenGL投影矩阵).

$$linearZ(z)=\frac{n}{f+z(n−f)}$$(119)

通过预先计算两个项 c0 和 c1 可以简化这个方程, 

$$c_1=\frac{f}{n}\\c_0=1-c_1\\linearZ(z)=\frac{1}{z⋅c_0+c_1}$$(120)

这一简化非常重要, 因为我们将线性z值传递给 118 中的`log2`. 由于除法在对数下变为取负, 可以使用 −log2(z⋅c0+c1)来避免除法.

```
#define MAX_LIGHT_COUNT 16 // 每个锥素的最大光源数

uniform uvec4 froxels; // res x, res y, count y, count y
uniform vec4 zParams;  // c0, c1, index scale, index bias

uint getDepthSlice() {
    return uint(max(0.0, log2(zParams.x * gl_FragCoord.z + zParams.y) *
            zParams.z + zParams.w));
}

uint getFroxelOffset(uint depthSlice) {
    uvec2 froxelCoord = uvec2(gl_FragCoord.xy) / froxels.xy;
    froxelCoord.y = (froxels.w - 1u) - froxelCoord.y;

    uint index = froxelCoord.x + froxelCoord.y * froxels.z +
            depthSlice * froxels.z * froxels.w;
    return index * MAX_FROXEL_LIGHT_COUNT;
}

uint slice = getDepthSlice();
uint offset = getFroxelOffset(slice);

// 计算光照
```

**清单 46:** 根据片段的屏幕坐标计算锥素索引的GLSL实现

为了高效地计算索引, 必须预先计算一些uniforms值. 用于预先计算这些uniforms值的代码见清单 47

```
froxels[0] = TILE_RESOLUTION_IN_PX;
froxels[1] = TILE_RESOLUTION_IN_PX;
froxels[2] = numberOfTilesInX;
froxels[3] = numberOfTilesInY;

zParams[0] = 1.0f - Z_FAR / Z_NEAR;
zParams[1] = Z_FAR / Z_NEAR;
zParams[2] = (MAX_DEPTH_SLICES - 1) / log2(Z_SPECIAL_NEAR / Z_FAR);
zParams[3] = MAX_DEPTH_SLICES;
```

**清单 47:** 预先计算锥素索引



##### 8.4.2.5 从锥素到深度

给定一个锥素索引 i, 一个特殊的近平面 sn, 一个远平面 f 和最大深度切片数 m, 方程 121 可以计算给定锥素的最小深度.

$$clusterToZ(i≥1,sn,f,m)=2^{(i−m)\frac{-log_2(\frac{sn}{f})}{m-1}}$$(121)

对于 i=0, z值为0. 此方程的结果在[0..1]范围内, 应该乘以 f 以得到以世界单位表示的距离.

计算着色器实现应该使用`exp2`而不是`pow`. 可以对除法进行预先计算, 并将其作为uniform值传递.



### 8.5 验证

...

#### 8.5.1 场景引用可视化



### 8.6 坐标系统



## 9 附录

### 9.1 镜面颜色

...

### 9.2 IBL的重要性采样

在离散区域中, 积分可以使用方程 124 中定义的采样进行近似.

$$L_{out}(n,v,\Theta) \equiv \frac{1}{N} \sum_{i}^{N} f(l_{i}^{uniform},v,\Theta) L_{\perp}(l_i) \left< n \cdot l_i^{uniform} \right>$$(124)

不幸的是, 计算这个积分需要的采样过多. 通常使用的一种技术是更频繁地选择更"重要"的采样, 这称为 *重要性采样*. 

在我们的例子中, 我们将使用微面片法向的分布 Dggx 作为重要样本的分布

使用重要性采样计算 Lout(n,v,Θ)的方法在方程125 中给出

$$L_{out}(n,v,\Theta) \equiv \frac{1}{N} \sum_{i}^{N} \frac{f(l_{i},v,\Theta)}{p(l_i,v,\Theta)} L_{\perp}(l_i) \left< n \cdot l_i \right>$$(125)

在方程 125 中, p 为 *重要性采样* li 分布的概率密度函数(PDF). 这些样本依赖于 hi, v 和 α. PDF的定义见方程 127.



hi 由我们选择的分布给出,*重要方向样本* li 为 v 绕 hi 的反射, 因此其PDF与 hi **不同**. 经变换后, 一个分布的PDF由下式给出:

$$p(T_r(x)) = p(x) |J(T_r)|$$(126)

其中 |J(Tr)|为变换的雅可比行列式. 在我们的例子中, 考虑从 hi 到 li 的变换, 其雅可比行列式在 127 中给出.

$$p(l,v,\Theta) = D(h,\alpha) \left<n\cdot h \right> |J_{h \rightarrow l}| \\|J_{h \rightarrow l}| = \frac{1}{4 \left<v\cdot h\right>}$$(127)

#### 9.2.1 选择重要方向

详细信息请参阅节9.3 给定均匀分布 (ζϕ,ζθ)(, 重要方向 ll 由方程 128 定义.

$$\phi = 2 \pi \zeta_{\phi} \\\theta = \cos^{-1} \sqrt{\frac{1 - \zeta_{\theta}}{(\alpha^2 - 1)\zeta_{\theta}+1}} \\l = \{ \cos \phi \sin \theta, \sin \phi \sin \theta, \cos \theta \}$$(128)

通常, 使用Hammersley均匀分布算法选择 (ζϕ,ζθ)(ζϕ,ζθ), 具体细节见节 9.4

#### 9.2.2 预过滤重要性采样

重要性采样生成重要方向时只考虑PDF; 特别是, 它忽略了IBL的实际内容. 如果后者在没有大量样本的区域中包含高频信息, 那么得到积分不准确. 这可以通过使用一种称为 *预过滤重要性采样* 的技术进行改进, 此外, 这种方法使用更少的样本就可以得到收敛的积分.

预过滤重要性采样使用多个环境图像, 这些图像采用的低通滤波越来越低. 这通常使用mipmap和盒式滤波实现, 非常高效. 根据样本重要性选择LOD, 即, 低概率样本使用更高的LOD索引(更多过滤).

[[Krivanek08](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-krivanek08)]

立方体贴图LOD通过以下方式确定:

$$lod &= \log_4 \left( K\frac{\Omega_s}{\Omega_p} \right) \\K &= 4.0 \\\Omega_s &= \frac{1}{N \cdot p(l_i)} \\\Omega_p &\approx \frac{4\pi}{6 \cdot \text{width} \cdot \text{height} }$$

其中 K 为根据经验确定的常数, p 为BRDF的PDF, Ωs 为与样本关联的立体角, Ωp 为与立方体贴图中的纹素相关联的立体角.

立方体贴图采样使用无缝三线性滤波. 对跨面的立方体贴图进行采样时, 使用OpenGL的无缝采样功能或任何其他能够避免/减少接缝的技术, 对保证采样正确非常重要.



### 9.3 选择BRDF采样的重要方向

为简单起见, 使用BRDF的 D 项作为PDF, 但PDF必须进行归一化, 使得半球上的积分为1:

$$\int_{\Omega}p(m)dm = 1 \\\int_{\Omega}D(m)(n \cdot m)dm = 1 \\\int_{\phi=0}^{2\pi}\int_{\theta=0}^{\frac{\pi}{2}}D(\theta,\phi) \cos \theta \sin \theta d\theta d\phi = 1 \\$$(129)

因此, BRDF的PDF可以用方程 130 表示:

$$p(\theta,\phi) = \frac{\alpha^2}{\pi(\cos^2\theta (\alpha^2-1) + 1)^2} \cos\theta \sin\theta$$

sinθ项来自立体角微分 sin⁡θdϕdθ, 因为我们对球面进行积分. 我们独立地对 θ 和 ϕ 进行采样:

$$p(\theta) &= \int_0^{2\pi} p(\theta,\phi) d\phi = \frac{2\alpha^2}{(\cos^2\theta (\alpha^2-1) + 1)^2} \cos\theta \sin\theta \\p(\phi) &= \frac{p(\theta,\phi)}{p(\phi)} = \frac{1}{2\pi}$$

对于各向同性的法线分布, 公式 p(ϕ) 是正确的.

然后, 计算每个变量的累积分布函数(CDF):

$$P(s_{\phi}) &= \int_{0}^{s_{\phi}} p(\phi) d\phi = \frac{s_{\phi}}{2\pi} \\P(s_{\theta}) &= \int_{0}^{s_{\theta}} p(\theta) d\theta = 2 \alpha^2 \left( \frac{1}{(2\alpha^4-4\alpha^2+2) \cos s_{\theta}^2 + 2\alpha^2 - 2} - \frac{1}{2\alpha^4-2\alpha^2} \right)$$

将 P(sϕ)和 P(sθ) 设置为随机变量 ζϕ 和 ζθ, 并分别求解 sϕ 和 sθ:

$$P(s_{\phi}) &= \zeta_{\phi} \rightarrow s_{\phi} = 2\pi\zeta_{\phi} \\P(s_{\theta}) &= \zeta_{\theta} \rightarrow s_{\theta} = \cos^{-1} \sqrt{\frac{1-\zeta_{\theta}}{(\alpha^2-1)\zeta_{\theta}+1}}$$

因此, 给定均匀分布 (ζϕ,ζθ), 重要方向 l 定义为:

$$\phi &= 2\pi\zeta_{\phi} \\\theta &= \cos^{-1} \sqrt{\frac{1-\zeta_{\theta}}{(\alpha^2-1)\zeta_{\theta}+1}} \\l &= \{ \cos\phi \sin\theta,\sin\phi \sin\theta,\cos\theta \}$$



### 9.4 Hammersley序列

```
vec2f hammersley(uint i, float numSamples) {
    uint bits = i;
    bits = (bits << 16) | (bits >> 16);
    bits = ((bits & 0x55555555) << 1) | ((bits & 0xAAAAAAAA) >> 1);
    bits = ((bits & 0x33333333) << 2) | ((bits & 0xCCCCCCCC) >> 2);
    bits = ((bits & 0x0F0F0F0F) << 4) | ((bits & 0xF0F0F0F0) >> 4);
    bits = ((bits & 0x00FF00FF) << 8) | ((bits & 0xFF00FF00) >> 8);
    return vec2f(i / numSamples, bits / exp2(32));
}
```

Hammersley序列生成器的C ++实现



### 9.5 预计算L用于基于图像的光照

LDFG 项仅依赖于n⋅v. 下面, 随意将法线设置为 n=[0,0,1], 并选择 v 满足 n⋅v. 向量 hi 为 DGGX(α) 重要方向样本 i .

```
float GDFG(float NoV, float NoL, float a) {
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return (2 * NoL) / (GGXV + GGXL);
}

float2 DFG(float NoV, float a) {
    float3 V;
    V.x = sqrt(1.0f - NoV*NoV);
    V.y = 0.0f;
    V.z = NoV;

    float2 r = 0.0f;
    for (uint i = 0; i < sampleCount; i++) {
        float2 Xi = hammersley(i, sampleCount);
        float3 H = importanceSampleGGX(Xi, a, N);
        float3 L = 2.0f * dot(V, H) * H - V;

        float VoH = saturate(dot(V, H));
        float NoL = saturate(L.z);
        float NoH = saturate(H.z);

        if (NoL > 0.0f) {
            float G = GDFG(NoV, NoL, a);
            float Gv = G * VoH / NoH;
            float Fc = pow(1 - VoH, 5.0f);
            r.x += Gv * (1 - Fc);
            r.y += Gv * Fc;
        }
    }
    return r * (1.0f / sampleCount);
}
```

LDFG 项的C++实现

### 9.6 球谐函数

|  符号  | 定义                                   |
| :----: | :------------------------------------- |
|  Kml   | 归一化因子                             |
| Pml(x) | 连带勒让德多项式                       |
|  yml   | 球谐函数基, 或SH基                     |
|  Lml   | 定义在单位球上的 L(s)L(s) 函数的SH系数 |

#### 9.6.1 基函数

单位球面上点的球面参数化:

$$\{ x, y, z \} = \{ \cos \phi \sin \theta, \sin \phi \sin \theta, \cos \theta \}$$

复球谐函数基由下式给出:

$$Y^m_l(\theta, \phi) = K^m_l e^{im\theta} P^{|m|}_l(\cos \theta), l \in N, -l <= m <= l$$

但我们只需要实数基:

$$y^{m > 0}_l &= \sqrt{2} K^m_l \cos(m \phi) P^m_l(\cos \theta) \\y^{m < 0}_l &= \sqrt{2} K^m_l \sin(m \phi) P^{|m|}_l(\cos \theta) \\y^0_l &= K^0_l P^0_l(\cos \theta)$$

归一化因子由下式给出:

$$K^m_l = \sqrt{\frac{(2l + 1)(l - |m|)!}{4 \pi (l + |m|)!}}$$

连带勒让德多项式 P|m|l 可以通过下式递归计算:

$$P^0_0(x) = 1 \\P^0_1(x) = x \\P^l_l(x) = (-1)^l (2l - 1)!!(1 - x^2)^{\frac{l}{2}} \\P^m_l(x) = \frac{ (2l - 1) x P^m_{l - 1} - (l + m - 1) P^m_{l - 2} }{l - m} \\$$

计算 y|m|l 需要先计算 P|m|l(z). 使用方程 134 中的递归关系很容易做到. 第三个递归可用于在表 20中进行"对角移动", 即计算 y00, y11, y22 等. 然后, 第四个递归可用于垂直移动.

| 波段指数 |    基函数 −l<=m<=l    |
| :------: | :-------------------: |
|   l=0    |          y00          |
|   l=1    |     y−11 y01 y11      |
|   l=2    | y−22 y−12 y02 y12 y22 |

**表 19:** 每个波段的基函数

递归地计算三角项也很容易:

$$C_m &\equiv \cos(m \phi) \\S_m &\equiv \sin(m \phi) \\\{ x, y, z \} &= \{ \cos \phi \sin \theta, \sin \phi \sin \theta, \cos \theta \}$$

使用和差化积公式:

$$\cos(m \phi + \phi) &= \cos(m \phi) \cos(\phi) - \sin(m \phi) \sin(\phi) \Leftrightarrow C_{m + 1} = \frac{(x C_m - y S_m)}{\sin(\theta)^{|m + 1|}} \\\sin(m \phi + \phi) &= \sin(m \phi) \sin(\phi) + \cos(m \phi) \sin(\phi) \Leftrightarrow S_{m + 1} = \frac{(x S_m - y C_m)}{\sin(\theta)^{|m + 1|}}$$

上面的方程有一个额外的项 sin(θ)−|m+1|, 但我们可以通过乘以 Pll(z)以及 sin(θ)|m+1|来补偿 P|m|l(z)递归中的项, 这大大简化了134 中的第三个方程, 因为 Pll(cosθ)sin(θ)−l=(−1)l(2l−1)!!

清单 50展示了用于计算非归一化SH基 yml(s)2√Kml 的C++代码:

```
static inline size_t SHindex(ssize_t m, size_t l) {
    return l * (l + 1) + m;
}

void computeShBasis(
        double* const SHb,
        size_t numBands,
        const vec3& s)
{
    // 单独处理 m=0, 因为它只有一个系数
    double Pml_2 = 0;
    double Pml_1 = 1;
    SHb[0] =  Pml_1;
    for (ssize_t l = 1; l < numBands; l++) {
        double Pml = ((2 * l - 1) * Pml_1 * s.z - (l - 1) * Pml_2) / l;
        Pml_2 = Pml_1;
        Pml_1 = Pml;
        SHb[SHindex(0, l)] = Pml;
    }
    double Pmm = 1;
    for (ssize_t m = 1; m < numBands ; m++) {
        Pmm = (1 - 2 * m) * Pmm;
        double Pml_2 = Pmm;
        double Pml_1 = (2 * m + 1)*Pmm*s.z;
        // l == m
        SHb[SHindex(-m, m)] = Pml_2;
        SHb[SHindex( m, m)] = Pml_2;
        if (m + 1 < numBands) {
            // l == m+1
            SHb[SHindex(-m, m + 1)] = Pml_1;
            SHb[SHindex( m, m + 1)] = Pml_1;
            for (ssize_t l = m + 2; l < numBands; l++) {
                double Pml = ((2 * l - 1) * Pml_1 * s.z - (l + m - 1) * Pml_2)
                        / (l - m);
                Pml_2 = Pml_1;
                Pml_1 = Pml;
                SHb[SHindex(-m, l)] = Pml;
                SHb[SHindex( m, l)] = Pml;
            }
        }
    }
    double Cm = s.x;
    double Sm = s.y;
    for (ssize_t m = 1; m <= numBands ; m++) {
        for (ssize_t l = m; l < numBands ; l++) {
            SHb[SHindex(-m, l)] *= Sm;
            SHb[SHindex( m, l)] *= Cm;
        }
        double Cm1 = Cm * s.x - Sm * s.y;
        double Sm1 = Sm * s.x + Cm * s.y;
        Cm = Cm1;
        Sm = Sm1;
    }
}
```

**清单 50:** 计算非归一化SH基的C++实现

前三个波段归一化的SH基函数 $y^m_l(s)$:

| Band |       m=−2        |        m=−1         |                m=0                |         m=1         |       m=2       |
| :--: | :---------------: | :-----------------: | :-------------------------------: | :-----------------: | :-------------: |
| l=0  |                   |                     |            121π−−√121π            |                     |                 |
| l=1  |                   |   −123π−−√y−123πy   |           123π−−√z123πz           |   −123π−−√x−123πx   |                 |
| l=2  | 1215π−−√xy1215πxy | −1215π−−√yz−1215πyz | 145π−−√(2z2−x2−y2)145π(2z2−x2−y2) | −1215π−−√xz−1215πxz | 1415π−−√(x2−y2) |

**表 20:** 每个波段归一化的基函数

#### 9.6.2 分解和重建

定义在球面上的函数 L(S)L(S) 可以投影到SH基上, 如下所示:

$$L^m_l = \int_\Omega L(s) y^m_l(s) ds \\L^m_l = \int_{\theta = 0}^{\pi} \int_{\phi = 0}^{2\pi} L(\theta, \phi) y^m_l(\theta, \phi) \sin \theta d\theta d\phi$$

注意, 每个 Lml 为3个值的向量, 每个RGB颜色通道一个.

SH系数的逆变换, 或重建, 或渲染由下式给出:

$$\hat{L}(s) = \sum_l \sum_{m = -l}^l L^m_l y^m_l(s)$$

#### 9.6.3 ⟨cosθ⟩的分解

由于 ⟨cosθ⟩ 与 ϕ 无关(不依赖方位角), 因此积分可简化为:

$$C^0_l &= 2\pi \int_0^{\pi} \left< \cos \theta \right> y^0_l(\theta) \sin \theta d\theta \\C^0_l &= 2\pi K^m_l \int_0^{\frac{\pi}{2}} P^0_l(\cos \theta) \cos \theta \sin \theta d\theta \\C^m_l &= 0, m != 0$$

在[[Ramamoorthi01](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-ramamoorthi01)]中给出了积分的解析解:

$$C_1 &= \sqrt{\frac{\pi}{3}} \\C_{odd} &= 0 \\C_{l, even} &= 2\pi \sqrt{\frac{2l + 1}{4\pi}} \frac{(-1)^{\frac{l}{2} - 1}}{(l + 2)(l - 1)} \frac{l!}{2^l (\frac{l!}{2})^2}$$

前几个系数为:

$$C_0 &= +0.88623 \\C_1 &= +1.02333 \\C_2 &= +0.49542 \\C_3 &= +0.00000 \\C_4 &= -0.11078$$

合理地近似 ⟨cosθ⟩只需要很少几个系数, 如图 95所示.



[![img](https://jerkwin.github.io/filamentcn/images/chart_sh_cos_thera_approx.png)](https://jerkwin.github.io/filamentcn/images/chart_sh_cos_thera_approx.png)

**图 95:** 用SH系数近似 cosθ

#### 9.6.4 卷积

具有圆对称性的核 hh 的卷积可以直接在SH空间中轻松应用:

$$(h * f)^m_l = \sqrt{\frac{4\pi}{2l + 1}} h^0_l(s) f^m_l(s)$$

方便地, $\sqrt{\frac{4\pi}{2l+1}}=\frac{1}{K^0_l}$, 所以在实践中我们将 Cl 预先乘以$\frac{1}{K^0_l}$, 得到一个更简单的表达式:

$$\hat{C}_{l, even} = 2\pi \frac{(-1)^{\frac{l}{2} - 1}}{(l + 2)(l - 1)} \frac{l!}{2^l (\frac{l!}{2})^2} \\\hat{C}_1 = \frac{2\pi}{3}$$

以下是计算 $C^l$ 的C++代码:

```
static double factorial(size_t n, size_t d = 1);

// < cos(theta) > 预先乘以1/K(0,l)的SH系数
double computeTruncatedCosSh(size_t l) {
    if (l == 0) {
        return M_PI;
    } else if (l == 1) {
        return 2 * M_PI / 3;
    } else if (l & 1) {
        return 0;
    }
    const size_t l_2 = l / 2;
    double A0 = ((l_2 & 1) ?1.0 : -1.0) / ((l + 2) * (l - 1));
    double A1 = factorial(l, l_2) / (factorial(l_2) * (1 << l));
    return 2 * M_PI * A0 * A1;
}

// 返回 n!/ d!
double factorial(size_t n, size_t d ) {
   d = std::max(size_t(1), d);
   n = std::max(size_t(1), n);
   double r = 1.0;
   if (n == d) {
       // 省略
   } else if (n > d) {
       for ( ; n>d ; n--) {
           r *= n;
       }
   } else {
       for ( ; d>n ; d--) {
           r *= d;
       }
       r = 1.0 / r;
   }
   return r;
}
```



### 9.7 Mitsuba的示例验证场景



### 9.8 使用锥素进行灯光指定

将灯光指定给锥素时, 可以使用两个计算着色器在GPU上实现. 第一个, 如清单 51所示, 在SSBO中创建锥素数据(4个平面+每个锥素的最小Z和最大Z), 并且只需运行一次. 着色器需要以下uniforms值:

投影矩阵: 用于渲染场景的投影矩阵(视图空间到剪切空间的变换).

逆投影矩阵: 用于渲染场景的投影矩阵的逆矩阵(剪切空间到视图空间的变换).

深度参数: $−log_2(\frac{z_{near}}{z_{far}})\frac{1}{maxSlices−1}$, 深度切片的最大数目, Z近和Z远.

剪切空间大小: $\frac{Fx×Fr}{w}×2$, 其中 Fx 为X轴上图块的数目, Fr 为图块的分辨率, 以像素为单位, w为渲染目标的宽度, 以像素为单位.

```
#version 310 es

precision highp float;
precision highp int;

#define FROXEL_RESOLUTION 80u

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(location = 0) uniform mat4 projectionMatrix;
layout(location = 1) uniform mat4 projectionInverseMatrix;
layout(location = 2) uniform vec4 depthParams; // index scale, index bias, near, far
layout(location = 3) uniform float clipSpaceSize;

struct Froxel {
    // 注意: 平面应存储在 vec4[4] 中,
    // 但Adreno着色器编译器有一个bug,
    // 可以导致无法在循环内正确地读取数据
    vec4 plane0;
    vec4 plane1;
    vec4 plane2;
    vec4 plane3;
    vec2 minMaxZ;
};

layout(binding = 0, std140) writeonly restrict buffer FroxelBuffer {
    Froxel data[];
} froxels;

shared vec4 corners[4];
shared vec2 minMaxZ;

vec4 projectionToView(vec4 p) {
    p = projectionInverseMatrix * p;
    return p / p.w;
}

vec4 createPlane(vec4 b, vec4 c) {
    // 标准平面方程, (0,0,0)
    return vec4(normalize(cross(c.xyz, b.xyz)), 1.0);
}

void main() {
    uint index = gl_WorkGroupID.x + gl_WorkGroupID.y * gl_NumWorkGroups.x +
            gl_WorkGroupID.z * gl_NumWorkGroups.x * gl_NumWorkGroups.y;

    if (gl_LocalInvocationIndex == 0u) {
        // 首先平铺屏幕并为当前贴片构建视锥
        vec2 renderTargetSize = vec2(FROXEL_RESOLUTION * gl_NumWorkGroups.xy);
        vec2 frustumMin = vec2(FROXEL_RESOLUTION * gl_WorkGroupID.xy);
        vec2 frustumMax = vec2(FROXEL_RESOLUTION * (gl_WorkGroupID.xy + 1u));

        corners[0] = vec4(
            frustumMin.x / renderTargetSize.x * clipSpaceSize - 1.0,
            (renderTargetSize.y - frustumMin.y) / renderTargetSize.y
			    * clipSpaceSize - 1.0,
            1.0,
            1.0
        );
        corners[1] = vec4(
            frustumMax.x / renderTargetSize.x * clipSpaceSize - 1.0,
            (renderTargetSize.y - frustumMin.y) / renderTargetSize.y
			    * clipSpaceSize - 1.0,
            1.0,
            1.0
        );
        corners[2] = vec4(
            frustumMax.x / renderTargetSize.x * clipSpaceSize - 1.0,
            (renderTargetSize.y - frustumMax.y) / renderTargetSize.y
			    * clipSpaceSize - 1.0,
            1.0,
            1.0
        );
        corners[3] = vec4(
            frustumMin.x / renderTargetSize.x * clipSpaceSize - 1.0,
            (renderTargetSize.y - frustumMax.y) / renderTargetSize.y
			    * clipSpaceSize - 1.0,
            1.0,
            1.0
        );

        uint froxelSlice = gl_WorkGroupID.z;
        minMaxZ = vec2(0.0, 0.0);
        if (froxelSlice > 0u) {
            minMaxZ.x = exp2((float(froxelSlice) - depthParams.y) * depthParams.x)
                    * depthParams.w;
        }
        minMaxZ.y = exp2((float(froxelSlice + 1u) - depthParams.y) * depthParams.x)
                * depthParams.w;
    }

    if (gl_LocalInvocationIndex == 0u) {
        vec4 frustum[4];
        frustum[0] = projectionToView(corners[0]);
        frustum[1] = projectionToView(corners[1]);
        frustum[2] = projectionToView(corners[2]);
        frustum[3] = projectionToView(corners[3]);

        froxels.data[index].plane0 = createPlane(frustum[0], frustum[1]);
        froxels.data[index].plane1 = createPlane(frustum[1], frustum[2]);
        froxels.data[index].plane2 = createPlane(frustum[2], frustum[3]);
        froxels.data[index].plane3 = createPlane(frustum[3], frustum[0]);
        froxels.data[index].minMaxZ = minMaxZ;
    }
}
```

**清单 51:** 锥素数据生成的GLSL实现(计算着色器)

清单 52所示的第二个计算着色器处理每一帧(如果相机和/或灯光发生变化), 并将所有灯光指定到各自的锥素. 这个着色器只依赖几个uniforms值(点光源/聚光灯和视图矩阵的数目)和四个SSBO:

灯光索引缓冲区: 对于每个锥素, 影响该锥素的所有灯光的索引. 首先写入点光源的索引, 如果剩余空间足够, 也会写入聚光灯的索引. 值0×7fffffffu将点光源和聚光灯分开, 和/或标记锥素灯光列表的末尾. 每个锥素都有最大数量的灯光(点光源+聚光灯).

点光源缓冲区: 描述场景中点光源的结构数组.

聚光灯缓冲区: 描述场景中聚光灯的结构数组.

锥素缓冲区: 以平面表示的锥素列表, 由前一个计算着色器创建.

```
#version 310 es
precision highp float;
precision highp int;

#define LIGHT_BUFFER_SENTINEL 0x7fffffffu
#define MAX_FROXEL_LIGHT_COUNT 32u

#define THREADS_PER_FROXEL_X 8u
#define THREADS_PER_FROXEL_Y 8u
#define THREADS_PER_FROXEL_Z 1u
#define THREADS_PER_FROXEL (THREADS_PER_FROXEL_X * \
        THREADS_PER_FROXEL_Y * THREADS_PER_FROXEL_Z)

layout(local_size_x = THREADS_PER_FROXEL_X,
       local_size_y = THREADS_PER_FROXEL_Y,
       local_size_z = THREADS_PER_FROXEL_Z) in;

// x = 点光源, y = 聚光灯
layout(location = 0) uniform uvec2 totalLightCount;
layout(location = 1) uniform mat4 viewMatrix;

layout(binding = 0, packed) writeonly restrict buffer LightIndexBuffer {
    uint index[];
} lightIndexBuffer;

struct PointLight {
    vec4 positionFalloff; // x, y, z, falloff
    vec4 colorIntensity;  // r, g, b, intensity
    vec4 directionIES;    // dir x, dir y, dir z, IES profile index
};

layout(binding = 1, std140) readonly restrict buffer PointLightBuffer {
    PointLight lights[];
} pointLights;

struct SpotLight {
    vec4 positionFalloff; // x, y, z, falloff
    vec4 colorIntensity;  // r, g, b, intensity
    vec4 directionIES;    // dir x, dir y, dir z, IES profile index
    vec4 angle;           // angle scale, angle offset, unused, unused
};

layout(binding = 2, std140) readonly restrict buffer SpotLightBuffer {
    SpotLight lights[];
} spotLights;

struct Froxel {
    // 注意: 平面应存储在 vec4[4] 中,
    // 但Adreno着色器编译器有一个bug,
    // 可以导致无法在循环内正确地读取数据
    vec4 plane0;
    vec4 plane1;
    vec4 plane2;
    vec4 plane3;
    vec2 minMaxZ;
};

layout(binding = 3, std140) readonly restrict buffer FroxelBuffer {
    Froxel data[];
} froxels;

shared uint groupLightCounter;
shared uint groupLightIndexBuffer[MAX_FROXEL_LIGHT_COUNT];

float signedDistanceFromPlane(vec4 p, vec4 plane) {
    // plane.w == 0.0, 简化计算
    return dot(plane.xyz, p.xyz);
}

void synchronize() {
    memoryBarrierShared();
    barrier();
}

void main() {
    if (gl_LocalInvocationIndex == 0u) {
        groupLightCounter = 0u;
    }
    memoryBarrierShared();

    uint froxelIndex = gl_WorkGroupID.x + gl_WorkGroupID.y * gl_NumWorkGroups.x +
            gl_WorkGroupID.z * gl_NumWorkGroups.x * gl_NumWorkGroups.y;
    Froxel current = froxels.data[froxelIndex];

    uint offset = gl_LocalInvocationID.x +
	        gl_LocalInvocationID.y * THREADS_PER_FROXEL_X;
    for (uint i = 0u; i < totalLightCount.x &&
		    groupLightCounter < MAX_FROXEL_LIGHT_COUNT &&
            offset + i < totalLightCount.x; i += THREADS_PER_FROXEL) {

        uint currentLight = offset + i;

        vec4 center = pointLights.lights[currentLight].positionFalloff;
        center.xyz = (viewMatrix * vec4(center.xyz, 1.0)).xyz;
        float r = inversesqrt(center.w);

        if (-center.z + r > current.minMaxZ.x &&
                -center.z - r <= current.minMaxZ.y) {
            if (signedDistanceFromPlane(center, current.plane0) < r &&
                signedDistanceFromPlane(center, current.plane1) < r &&
                signedDistanceFromPlane(center, current.plane2) < r &&
                signedDistanceFromPlane(center, current.plane3) < r) {

                uint index = atomicAdd(groupLightCounter, 1u);
                groupLightIndexBuffer[index] = currentLight;
            }
        }
    }

    synchronize();

    uint pointLightCount = groupLightCounter;
    offset = froxelIndex * MAX_FROXEL_LIGHT_COUNT;

    for (uint i = gl_LocalInvocationIndex; i < pointLightCount;
            i += THREADS_PER_FROXEL) {
        lightIndexBuffer.index[offset + i] = groupLightIndexBuffer[i];
    }

    if (gl_LocalInvocationIndex == 0u) {
        if (pointLightCount < MAX_FROXEL_LIGHT_COUNT) {
            lightIndexBuffer.index[offset + pointLightCount] = LIGHT_BUFFER_SENTINEL;
        }
    }
}
```

**清单 52:** 灯光到锥素的GLSL实现(计算着色器)

## 10 修订

...

## 11 参考文献

[**Ashdown98**] Ian Ashdown. 1998. Parsing the IESNA LM-63 photometric data file. http://lumen.iee.put.poznan.pl/kw/iesna.txt

[**Ashikhmin00**] Michael Ashikhmin, Simon Premoze and Peter Shirley. A Microfacet-based BRDF Generator. *SIGGRAPH '00 Proceedings*, 65-74.

[**Ashikhmin07**] Michael Ashikhmin and Simon Premoze. 2007. Distribution-based BRDFs.

[**Burley12**] Brent Burley. 2012. Physically Based Shading at Disney. *Physically Based Shading in Film and Game Production, ACM SIGGRAPH 2012 Courses*.

[**Estevez17**] Alejandro Conty Estevez and Christopher Kulla. 2017. Production Friendly Microfacet Sheen BRDF. *ACM SIGGRAPH 2017*.

[**Hammon17**] Earl Hammon. 217. PBR Diffuse Lighting for GGX+Smith Microsurfaces. *GDC 2017*.

[**Heitz14**] Eric Heitz. 2014. Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs. *Journal of Computer Graphics Techniques*, 3 (2).

[**Heitz16**] Eric Heitz et al. 2016. Multiple-Scattering Microfacet BSDFs with the Smith Model. *ACM SIGGRAPH 2016*.

[**Hill12**] Colin Barré-Brisebois and Stephen Hill. 2012. Blending in Detail. http://blog.selfshadow.com/publications/blending-in-detail/

[**Karis13**] Brian Karis. 2013. Specular BRDF Reference. http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html

[**Karis14**] Brian Karis. 2014. Physically Based Shading on Mobile. https://www.unrealengine.com/blog/physically-based-shading-on-mobile

[**Kelemen01**] Csaba Kelemen et al. 2001. A Microfacet Based Coupled Specular-Matte BRDF Model with Importance Sampling. *Eurographics Short Presentations*.

[**Krystek85**] M. Krystek. 1985. An algorithm to calculate correlated color temperature. *Color Research & Application*, 10 (1), 38–40.

[**Krivanek08**] Jaroslave Krivànek and Mark Colbert. 2008. Real-time Shading with Filtered Importance Sampling. *Eurographics Symposium on Rendering 2008*, Volume 27, Number 4.

[**Kulla17**] Christopher Kulla and Alejandro Conty. 2017. Revisiting Physically Based Shading at Imageworks. *ACM SIGGRAPH 2017*

[**Lagarde14**] Sébastien Lagarde and Charles de Rousiers. 2014. Moving Frostbite to PBR. *Physically Based Shading in Theory and Practice, ACM SIGGRAPH 2014 Courses*.

[**Lagarde18**] Sébastien Lagarde and Evgenii Golubev. 2018. The road toward unified rendering with Unity’s high definition rendering pipeline. *Advances in Real-Time Rendering in Games, ACM SIGGRAPH 2018 Courses*.

[**Lazarov13**] Dimitar Lazarov. 2013. Physically-Based Shading in Call of Duty: Black Ops. *Physically Based Shading in Theory and Practice, ACM SIGGRAPH 2013 Courses*.

[**McAuley15**] Stephen McAuley. 2015. Rendering the World of Far Cry 4. *GDC 2015*.

[**McGuire10**] Morgan McGuire. 2010. Ambient Occlusion Volumes. *High Performance Graphics*.

[**Narkowicz14**] Krzysztof Narkowicz. 2014. Analytical DFG Term for IBL. https://knarkowicz.wordpress.com/2014/12/27/analytical-dfg-term-for-ibl

[**Neubelt13**] David Neubelt and Matt Pettineo. 2013. Crafting a Next-Gen Material Pipeline for The Order: 1886. *Physically Based Shading in Theory and Practice, ACM SIGGRAPH 2013 Courses*.

[**Oren94**] Michael Oren and Shree K. Nayar. 1994. Generalization of lambert's reflectance model. *SIGGRAPH*, 239–246. ACM.

[**Pattanaik00**] Sumanta Pattanaik00 et al. 2000. Time-Dependent Visual Adaptation For Fast Realistic Image Display. *SIGGRAPH '00 Proceedings of the 27th annual conference on Computer graphics and interactive techniques*, 47-54.

[**Ramamoorthi01**] Ravi Ramamoorthi and Pat Hanrahan. 2001. On the relationship between radiance and irradiance: determining the illumination from images of a convex Lambertian object. *Journal of the Optical Society of America*, Volume 18, Number 10, October 2001.

[**Revie12**] Donald Revie. 2012. Implementing Fur in Deferred Shading. *GPU Pro 2*, Chapter 2.

[**Russell15**] Jeff Russell. 2015. Horizon Occlusion for Normal Mapped Reflections. http://marmosetco.tumblr.com/post/81245981087

[**Schlick94**] Christophe Schlick. 1994. An Inexpensive BRDF Model for Physically-Based Rendering. *Computer Graphics Forum*, 13 (3), 233–246.

[**Walter07**] Bruce Walter et al. 2007. Microfacet Models for Refraction through Rough Surfaces. *Proceedings of the Eurographics Symposium on Rendering*.



