# Filament材质说明

## 2 概述

基于物理的渲染(PBR)

### 2.1 核心概念

材质: 材质 定义表面的视觉外观



材质模型: 也称 *着色模型* 或 *光照模型*, 材质模型定义表面的内在特性;

直接影响光照的计算方式, 从而影响表面的外观;



## 3 材质模型

- 光亮(或标准)
- 次表面
- 布料
- 无光亮
- 镜面光泽(用于以前的模型)

### 3.1 光亮模型





用于描述大量的非金属表面(*电介质*)或金属表面(*导体*).

|                                 参数 | 定义                                                         |
| -----------------------------------: | :----------------------------------------------------------- |
|                   **baseColor 基色** | 非金属表面的漫反射反照率, 金属表面的镜面反射颜色             |
|                  **metallic 金属度** | 表面看起来是电介质(0.0)还是导体(1.0). 通常作为二进制值(0或1) |
|                 **roughness 粗糙度** | 表面的感知光滑程度(0.0)或粗糙程度(1.0). 光滑的表面会呈现出清晰的反射 |
|               **reflectance 反射率** | 垂直入射时电介质表面的Fresnel反射率. 直接控制了反射的强度    |
|                   **clearCoat 涂层** | 透明涂层的强度                                               |
|    **clearCoatRoughness 涂层粗糙度** | 透明涂层的感知光滑程度或粗糙程度                             |
|            **anisotropy 各向异性度** | 切线或副切线方向的各向异性程度                               |
| **anisotropyDirection 各向异性方向** | 局部表面方向                                                 |
|      **ambientOcclusion 环境光遮蔽** | 定义表面点的环境光可及性. 它是每个像素的阴影因子, 介于0.0和1.0之间 |
|                      **normal 法线** | 使用 *凹凸贴图* (*法线贴图*)作为扰动表面的细节法线           |
|         **clearCoatNormal 涂层法线** | 使用 *凹凸贴图* (*法线贴图*)作为扰动透明涂层的细节法线       |
|                  **emissive 自发光** | 额外的漫反射反照用于模拟自发光表面(例如霓虹灯等). 此参数主要用于具有泛光通道的HDR管线 |
| **postLightingColor 后处理光照颜色** | 可以与光照计算结果混合的额外颜色. 见`postLightingBlending`   |

**表 1:** 标准模型的参数





|                                 参数 |  类型  |         范围          | 备注                               |
| -----------------------------------: | :----: | :-------------------: | :--------------------------------- |
|                   **baseColor 基色** | float4 |        [0..1]         | 预乘的线性RGB                      |
|                  **metallic 金属度** | float  |        [0..1]         | 应为0或1                           |
|                 **roughness 粗糙度** | float  |        [0..1]         |                                    |
|               **reflectance 反射率** | float  |        [0..1]         | 首选值 > 0.35                      |
|                   **clearCoat 涂层** | float  |        [0..1]         | 应为0或1                           |
|    **clearCoatRoughness 涂层粗糙度** | float  |        [0..1]         | 重新映射到[0..0.6]                 |
|            **anisotropy 各向异性度** | float  |        [−1..1]        | 当此值为正时, 各向异性位于切线方向 |
| **anisotropyDirection 各向异性方向** | float3 |        [0..1]         | 线性RGB, 编码切线空间中的方向向量  |
|      **ambientOcclusion 环境光遮蔽** | float  |        [0..1]         |                                    |
|                      **normal 法线** | float3 |        [0..1]         | 线性RGB, 编码切线空间中的方向向量  |
|         **clearCoatNormal 涂层法线** | float3 |        [0..1]         | 线性RGB, 编码切线空间中的方向向量  |
|                  **emissive 自发光** | float4 | rgb=[0..1], a=[-n..n] | Alpha为是曝光补偿                  |
| **postLightingColor 后处理光照颜色** | float4 |        [0..1]         | 预乘的线性RGB                      |

**表 2:** 标准模型参数的范围和类型



#### 3.11 基色

`基色`属性定义了对象的感知颜色(有时称为反照率). 

`基色`的效果取决于表面的性质, 由`金属度`属性控制, 



非金属(电介质): 定义表面的漫反射颜色. 

如果使用0到255进行编码, 真实世界的值通常处于 [10..240][10..240] 范围内, 如果使用0到1进行编码, 则处于 [0.04..0.94][0.04..0.94] 范围内. 

|           金属 |       sRGB       | 十六进值 | 颜色 |
| -------------: | :--------------: | :------: | :--- |
|       煤炭Coal | 0.19, 0.19, 0.19 | #323232  |      |
|     橡胶Rubber | 0.21, 0.21, 0.21 | #353535  |      |
|          泥Mud | 0.33, 0.24, 0.19 | #553d31  |      |
|       木材Wood | 0.53, 0.36, 0.24 | #875c3c  |      |
| 植被Vegetation | 0.48, 0.51, 0.31 | #7b824e  |      |
|        砖Brick | 0.58, 0.49, 0.46 | #947d75  |      |
|         沙Sand | 0.69, 0.66, 0.52 | #b1a884  |      |
| 混凝土Concrete | 0.75, 0.75, 0.73 | #c0bfbb  |      |

**表 3:** 常见非金属的`基色`



金属(导体): 定义表面的镜面反射颜色. 

 如果使用0到255进行编码, 真实世界的值通常处于 [170..255][170..255] 范围内, 如果使用0到1进行编码, 则处于 [0.66..1.0][0.66..1.0] 范围内.

|      Metal |       sRGB       | Hexadecimal | Color |
| ---------: | :--------------: | :---------: | :---- |
|   银Silver | 0.97, 0.96, 0.91 |   #f7f4e8   |       |
| 铝Aluminum | 0.91, 0.92, 0.92 |   #e8eaea   |       |
| 钛Titanium | 0.76, 0.73, 0.69 |   #c1baaf   |       |
|     铁Iron | 0.77, 0.78, 0.78 |   #c4c6c6   |       |
| 铂Platinum | 0.83, 0.81, 0.78 |   #d3cec6   |       |
|     金Gold | 1.00, 0.85, 0.57 |   #ffd891   |       |
|  黄铜Brass | 0.98, 0.90, 0.59 |   #f9e596   |       |
|   铜Copper | 0.97, 0.74, 0.62 |   #f7bc9e   |       |

**表 4:** 常见金属的`基色`



#### 3.1.2 金属度



#### 3.1.3 粗糙度



#### 3.1.4 非金属



#### 3.1.5 金属



#### 3.1.6 反射率



#### 3.1.7 透明涂层



#### 3.1.8 透明涂层粗糙度

#### 3.1.9 各向异性度

#### 3.1.10 各向异性方向

#### 3.1.11 环境光遮蔽

#### 3.1.12 法线

#### 3.1.13 透明涂层法线

#### 3.1.14 自发光



#### 3.1.15 后处理光照颜色

### 3.2 次表面模型



### 3.3 布料模型

服和织物通常由松散连接的线制成,线可以吸收和散射入射光. 与坚硬的表面相比, 布料的特点是镜面波瓣更加柔和, 具有较大的衰减, 以及由前向/后向散射引起的模糊光照.



现出双色调镜面反射颜色 天鹅绒



####  3.3.1 光泽颜色

#### 3.3.2 次表面颜色



## 4 材质定义

- 名称
- 用户参数
- 材质模型
- 必需属性
- 插值(称为 *变量*)
- 光栅状态(混合模式等)
- 着色器代码(片段着色器, 可选的顶点着色器)



### 4.2 `Material`块

#### 通用: name

#### 通用: shadingModel

lit, subsurface, cloth, unlit, specularGlossiness

通用: parameters

通用: variantFilter

通用: flipUV

Vertex and attributes: requires

顶点及属性: variables

顶点及属性: vertexDomain

顶点及属性: interpolation

混合与透明: blending

混合与透明: postLightingBlending

Blending and transparency: transparency

混合与透明: maskThreshold

光栅化: culling

光栅化: colorWrite

光栅化: depthWrite

光栅化: depthCulling

光栅化: doubleSided

光照: shadowMultiplier

光照: clearCoatIorChange

光照: multiBounceAmbientOcclusion

光照: specularAmbientOcclusion

#### 4.2.23 抗锯齿: specularAntiAliasing

#### 4.2.24 抗锯齿: specularAntiAliasingVariance

介于0和`1之间的值. 默认为0.15.
当使用镜面抗锯齿时, 设置滤波内核的屏幕空间方差. 
高的值可以增加滤波的效果, 但可能会增加不需要区域的粗糙度.

#### 4.2.25 抗锯齿: specularAntiAliasingThreshold

介于0和`1之间的值. 默认为0.2.
当使用镜面抗锯齿时, 设置估计误差的裁剪阈值. 如果设置为0, 会禁用镜面抗锯齿.

### 4.3 Vertex块

### 4.4 片段块

必须使用片段块来控制材质的片段着色阶段. 顶点块必须包含有效的ESSL 3.0代码
可以在顶点块内随意创建多个函数, 但 必须 声明material函数:

```
fragment {
    void material(inout MaterialInputs material) {
        prepareMaterial(material);
        // 片段着色代码
    }
}
```

在运行时着色系统会自动调用此函数, 这样你能够使用`MaterialInputs`结构读取和修改材质属性.

结构的完整定义可以在 材质片段输入 部分找到. 结构的完整定义可以在 材质模型 部分找到.



`material()`函数的目标是计算特定于所选着色模型的材质属性. 

#### 4.4.1 prepareMaterial函数

请注意, 退出`material()`函数之前必须调用`prepareMaterial(material)`. 这个`prepareMaterial`函数设置了材质模型的内部状态.

同样重要的是记住, `normal`属性, 如 材质片段输入 部分所述, 只有在调用`prepareMaterial()` *之前* 修改才有效果. 

#### 4.4.2 材质片段输入

```
struct MaterialInputs {
    float4 baseColor;           // 默认: float4(1.0)
    float4 emissive;            // 默认: float4(0.0)
    float4 postLightingColor;   // 默认: float4(0.0)

    // 对于unlit着色模型, 没有其他字段可用
    float  roughness;           // 默认: 1.0
    float  metallic;         // 默认: 0.0, 不适用于布料或镜面光泽模型
    float  reflectance;         // 默认: 0.5, 不适用于布料或镜面光泽模型
    float  ambientOcclusion;    // 默认: 0.0

    // 当着色模型为次表面或Cloth时不可用
    float  clearCoat;           // 默认: 1.0
    float  clearCoatRoughness;  // 默认: 0.0
    float3 clearCoatNormal;     // 默认: float3(0.0, 0.0, 1.0)
    float  anisotropy;          // 默认: 0.0
    float3 anisotropyDirection; // 默认: float3(1.0, 0.0, 0.0)

    // 只有当着色模型为次表面时才可用
    float  thickness;           // 默认: 0.5
    float  subsurfacePower;     // 默认: 12.234
    float3 subsurfaceColor;     // 默认: float3(1.0)

    // 只有当着色模型为布料时才可用
    float3 sheenColor;         // 默认: sqrt(baseColor)
    float3 subsurfaceColor;    // 默认: float3(0.0)

    // 只有当着色模型为镜面光泽时才可用
    float3 specularColor;       // 默认: float3(0.0)
    float  glossiness;          // 默认: 0.0

    // 当着色模型为unlit时不可用
    // 必须在调用prepareMaterial()之前设置
    float3 normal;             // 默认: float3(0.0, 0.0, 1.0)
}
```

### 4.5 着色器公共API



#### 4.5.3 矩阵

| 名称                         |   类型   | 说明                                     |
| :--------------------------- | :------: | :--------------------------------------- |
| **getViewFromWorldMatrix()** | float4×4 | 从世界空间转换为视图/眼睛空间的矩阵      |
| **getWorldFromViewMatrix()** | float4×4 | 从视图/眼睛空间转换为世界空间的矩阵      |
| **getClipFromViewMatrix()**  | float4×4 | 从视图/眼睛空间转换为剪辑(NDC)空间的矩阵 |
| **getViewFromClipMatrix()**  | float4×4 | 从剪辑(NDC)空间转换为视图/眼睛空间的矩阵 |
| **getClipFromWorldMatrix()** | float4×4 | 从世界空间转换为剪辑(NDC)空间的矩阵      |
| **getWorldFromClipMatrix()** | float4×4 | 从剪辑(NDC)空间转换为世界空间的矩阵      |



#### 4.5.6 仅限于片段 

| 名称                                |   类型   | 说明                                                         |
| :---------------------------------- | :------: | :----------------------------------------------------------- |
| **getWorldTangentFrame()**          | float3×3 | 矩阵, 每一列包含了世界空间中顶点的`tangent` (`frame[0]`), `bi-tangent` (`frame[1]`)和`normal` (`frame[2]`). 如果材质不计算凹凸贴图的切线空间法线, 或者阴影不是各向异性的, 那么此矩阵中只有`normal`有效. |
| **getWorldPosition()**              |  float3  | 片段在世界空间中的位置(见后文有关世界空间的说明)             |
| **getWorldViewVector()**            |  float3  | 世界空间中从片段位置到眼睛的归一化向量                       |
| **getWorldNormalVector()**          |  float3  | 凹凸贴图后的世界空间中的归一化法线(必须在`prepareMaterial()`之后使用) |
| **getWorldGeometricNormalVector()** |  float3  | 凹凸贴图前世界空间中的归一化法线(必须在`prepareMaterial()`之前使用) |
| **getWorldReflectedVector()**       |  float3  | 视线向量关于法线的反射(必须在`prepareMaterial()`之后使用)    |
| **getNdotV()**                      |  float   | `dot(normal, view)`的结果, 始终严格大于0 (必须在`prepareMaterial()`之后使用) |
| **getColor()**                      |  float4  | 片段的插值颜色, 如果需要颜色属性                             |
| **getUV0()**                        |  float2  | UV坐标的第一个插值集合, 如果需要uv0属性                      |
| **getUV1()**                        |  float2  | UV坐标的第一个插值集合, 如果需要uv1属性                      |
| **getMaskThreshold()**              |  float   | 返回屏蔽阈值, 只有当`blending`设置为`masked`时才可用         |
| **inverseTonemap(float3)**          |  float3  | 将逆色调映射运算用于指定的线性sRGB颜色, 并返回线性sRGB颜色. 此运算可以采用近似 |
| **inverseTonemapSRGB(float3)**      |  float3  | 将逆色调映射运算用于指定的非线性sRGB颜色, 并返回线性sRGB颜色. 此运算可以采用近似 |
| **luminance(float3)**               |  float   | 计算指定线性sRGB颜色的亮度                                   |