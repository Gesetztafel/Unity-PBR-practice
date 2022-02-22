# Physically Based Rendering in Filament

# 2 概述

## 2.1 原理



实时移动性能

质量

易用性





## 2.2 基于物理的渲染

具有艺术性,生产效率高

基于物理的渲染,更准确地表现材质及其与光的相互作用



将材质和光照分离

可以更轻松地创建在所有光照条件下看起来都很精确的真实资源

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

多种材质模型, 用以简化对各种表面特征的描述

将标准模型, 透明涂层模型和各向异性模型结合起来, 形成一个更灵活更强大的模型



## 4.1 标准模型

模型的目标是表现标准材质的外观

BSDF(双向散射分布函数, Bidirectional Scattering Distribution Function)

BRDF(双向反射分布函数, Bidirectional Reflectance Distribution Function)和

BTDF(双向透射函数, Bidirectional Transmittance Function).



侧重于BRDF, 并且忽略BTDF, 或对其使用很粗糙的近似

正确地模拟具有短的平均自由程的反射, 各向同性, 电介质或导体表面.



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

微面片BRDF，

BRDF指出, 表面在微观层面上并不光滑, 而是由大量随机排列的平面碎片组成, 这些平面碎片称为微面片

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



由于此方程对镜面反射分量和漫反射分量都有效, 因此不同之处在于微面片BRDF的fmfm.

此方程用于在 *微观层面* 上对半球进行积分:

[![img](https://jerkwin.github.io/filamentcn/images/diagram_micro_vs_macro.png)](https://jerkwin.github.io/filamentcn/images/diagram_micro_vs_macro.png)

**图 6:** 对单个点的表面响应进行建模需要在微观层面上进行积分



在宏观层面上, 表面被视为是平坦的. 

假定从单个方向照亮的着色片段对应于表面上的单个点, 就有助于简化我们的方程.



在微观层面, 表面并不是平坦的, 我们不能再假定单一方向的光线(但我们可以假定入射光线是平行的). 在给定一束平行入射光线的情况下, 由于微面片会向不同的方向散射光, 因此我们必须将半球上的表面响应进行积分, 表面在上图中以m表示



对每个着色片段, 计算微面片在半球上的完整积分是不实际的. 因此, 我们需要对镜面反射分量和漫反射分量的积分进行近似.

## 4.2 电介质和导体

金属(导体)表面

非金属(电介质)表面

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

$V(v,l,\alpha) = \frac{0.5}{\NoL [n\cdot v (1 - \alpha) + \alpha] + n\cdot v [\NoL (1 - \alpha) + \alpha]}$(16)

```
float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
    float a = roughness;
    float GGXV = NoL * (NoV * (1.0 - a) + a);
    float GGXL = NoV * (NoL * (1.0 - a) + a);
    return 0.5 / (GGXV + GGXL);
}
```



[[Hammon17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-hammon17)]

$V(v,l,\alpha) = \frac{0.5}{\text{lerp}(2 (\NoL) (n\cdot v), \NoL + n\cdot v, \alpha)}$(17)

### 4.4.3 Fresnel(镜面F)

Fresnel效应,模拟 观察者看到的由表面反射的光的多少取决于观察角度(视角).

反射的光量不仅取决于视角, 还取决于材料的折射率(IOR, index of refraction). 

沿法向入射(垂直入射, 入射光线垂直于表面或入射角为0度)时, 可以根据IOR计算出反射回来的光量 f0, 对于光滑的材料, 以掠射角反射回来的光量 f90 接近100%.



Fresnel项定义了光在两种不同介质的界面处如何反射和折射, 或反射和透射能量的比例. [[Schlick94](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-schlick94)]给出了Cook-Torrance镜面BRDF的Fresnel项的快速近似计算公式:

$F_{Schlick}(v,h,f_0,f_90) = f_0 + (f_90 - f_0)(1 - v\cdot h)^5$(18)

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

$f_d(v,l) = \frac{\sigma}{\pi} \frac{1}{| n\cdot v | | \NoL |}\int_\Omega D(m,\alpha) G(v,l,m) (v \cdot m) (l \cdot m) dm$(19)

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

$\fDiffuse(v,l) = \frac{\sigma}{\pi} \schlick(n,l,1,\fGrazing) \schlick(n,v,1,\fGrazing)$

其中


$\fGrazing=0.5 + 2 \cdot \alpha \cos^2\theta_d$(22)



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



[14]

[ 17]GDC 2017-GGX_Smith Diffuse

[18] COD

### 4.7.2 镜面反射的能量损失

Cook-Torrance BRDF 微面片层面

计算光-单次反弹

导致高粗糙度时出现能量损失



单重散射(左)与多重散射



白炉测试



[[Heitz16](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-heitz16)] 多重散射BRDF的随机估计—— mean free path



[[Kulla17](https://jerkwin.github.io/filamentcn/Filament.md.html#citation-kulla17)] Kulla&Conty

能量补偿项,额外BRDF波瓣

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

$D_{aniso}(h,\alpha) = \frac{1}{\pi \alpha_t \alpha_b} \frac{1}{[(\frac{t \cdot h}{\alpha_t})^2 + (\frac{b \cdot h}{\alpha_b})^2 + (\NoH)^2]^2}$

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

$G(v,l,h,\alpha) = \frac{\chi^+(\VoH) \chi^+(\LoH)}{1 + \Lambda(v) + \Lambda(l)}$

$\Lambda(m) = \frac{-1 + \sqrt{1 + \alpha_0^2 \tan^2\theta_m}}{2} = \frac{-1 + \sqrt{1 + \alpha_0^2 \frac{1 - \cos^2 \theta_m}{\cos^2 \theta_m}}}{2}$

其中 $\alpha_0 = \sqrt{\cos^2 \phi_0 \alpha_x^2 + \sin^2 \phi_0 \alpha_y^2}$

推导后:$V_{aniso}(\NoL,\NoV,\alpha) = \frac{1}{2[(\NoL)\hat{\Lambda}_v+(\NoV)\hat{\Lambda}_l]} \\\hat{\Lambda}_v = \sqrt{\alpha^2_t(t \cdot v)^2+\alpha^2_b(b \cdot v)^2+(\NoV)^2} \\\hat{\Lambda}_l = \sqrt{\alpha^2_t(t \cdot l)^2+\alpha^2_b(b \cdot l)^2+(\NoL)^2}$

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

##### 4.12.1.1  光泽颜色

#### 4.12.2  布料漫反射BRDF

#### 4.12.3 布料参数化



## 5 光照

光照环境的正确性和一致性;

灯光 支持,分为两类, 直接光照和间接光照:

**直接光照**: 点光源, 光度学光源, 面光源.

**间接光照**: 基于图像的灯光(IBL), 用于局部[2](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-localprobesmobile)和远程光探头.



### 5.1 



### 5.2 



### 5.3 基于图像的光照(IBL)

在现实生活中, 光来自各个方向, 或是直接来自光源, 或是间接来自环境中物体的反弹, 并在这个过程中被部分吸收. 

在某种程度上, 可以将物体周围的整个环境视为光源. 

图像, 特别是立方体贴图, 是编码这种"环境光"的好方法. 这称为基于图像的光照(IBL), 或有时称为间接光照.



基于图像的光照存在局限性. 

显然, 必须以某种方式获取环境图像, 正如我们将在下面看到的那样, 在将其用于光照之前, 需要进行预处理. 

通常, 环境图像是在现实世界中离线获取的, 或者由引擎离线或实时生成; 无论哪种方式, 都需要使用局部或远程探头.



探头可用于获取远程或局部的环境.



整个环境都会为物体表面上的特定点提供光; 这称为*辐照度* (EE). 

从物体反弹出的光称为辐射(LoutLout). 

入射光照必须一致性地用于BRDF的漫反射和镜面反射部分.



基于图像的光照(IBL)的辐照度和材质模型(BRDF) f(Θ)f(Θ)[5](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-ibl1)之间的相互作用所产生的辐射 LoutLout 的计算方法如下:

Lout(n,v,Θ)=∫Ωf(l,v,Θ)L⊥(l)⟨n⋅l⟩dl(76)



### 5.3.1 IBL类型

- 远程光探头

  , 用于捕捉"无限远"处的光照信息, 可以忽略视差. 远程探头通常包括天空, 远处的景观特征或建筑物等. 它们可以由渲染引擎捕捉, 也可以高动态范围图像(HDRI)的形式从相机获得.

  

- 局部光探头

  , 用于从特定角度捕捉世界的某个区域. 捕捉会投影到立方体或球体上, 具体取决于周围的几何体. 局部探头比远程探头更精确, 在为材质添加局部反射时特别有用.

  

- 平面反射

  , 用于通过渲染镜像场景来捕捉反射. 此技术只适用于平面, 如建筑地板, 道路和水.

  

- **屏幕空间反射**, 基于在深度缓冲区使用光线行进方法渲染的场景(例如使用前一帧)来捕捉反射. SSR效果很好, 但可能非常昂贵.



必须区分静态和动态IBL. 

实现完全动态的昼夜循环需要动态地重新计算远程光探头[6](https://jerkwin.github.io/filamentcn/Filament.md.html#endnote-ibltypes1). 平面和屏幕空间反射本质都是动态的.



### 5.3.2 IBL单位



### 5.3.3 处理光探头



- 镜面反射率: 预滤波重要性采样与拆分求和近似
- **漫反射率**: 辐照度贴图和球谐函数

### 5.3.4 远程光探头

#### 5.3.4.1 漫反射BRDF积分





#### 5.3.4.2 高光BRDF积分





#### 5.3.4.3 DFG1 和 DFG2 项的可视化



#### 5.3.4.4 LD 项的可视化





#### 5.3.4.5 间接镜面反射分量和间接漫反射分量的可视化



#### 5.3.4.6 IBL计算的实现



#### 5.3.4.7 多重散射的预积分



#### 5.3.4.8 总结



### 5.3.5 透明涂层



### 5.3.6 各向异性



### 5.3.7 次表面



### 5.3.8 布料



### 5. 



### 5. 

### 5. 

### 5. 

### 5. 

### 5. 

### 5. 



# 
