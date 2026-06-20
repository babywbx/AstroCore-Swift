<div align="center"><a name="readme-top"></a>

# AstroCore

纯 Swift 实现的高精度西洋占星天文计算库，覆盖 1800–2100 年。<br/>
本地验证、分级精度声明，零运行时依赖，线程安全。

> 本 README 描述 v3 package 拆分：
> `AstroCore` 提供底层天文计算，`AstroAstrology` 提供占星模型，
> `AstroCoreLocations` 提供可选城市检索数据。

[English](./README.md) · [报告问题][github-issues-link] · [更新日志](./CHANGELOG.md) · [Releases][github-release-link]

<!-- SHIELD GROUP -->

[![][github-stars-shield]][github-stars-link]
[![][github-forks-shield]][github-forks-link]
[![][github-issues-shield]][github-issues-link]
[![][github-license-shield]][github-license-link]<br/>
[![][github-contributors-shield]][github-contributors-link]

</div>

<details>
<summary><kbd>目录</kbd></summary>

#### TOC

- [✨ 特性](#-特性)
- [📦 安装](#-安装)
- [🚀 使用](#-使用)
  - [☀️ 太阳星座](#️-太阳星座)
  - [🌙 月亮星座](#-月亮星座)
  - [🪐 行星位置](#-行星位置)
  - [♈ 上升星座 (ASC)](#-上升星座-asc)
  - [🏠 宫位系统](#-宫位系统)
  - [📊 批量本命盘](#-批量本命盘)
  - [🌐 城市数据库（可选）](#-城市数据库可选)
  - [🔧 底层 API](#-底层-api)
- [🎯 精度](#-精度)
- [⚡ 性能](#-性能)
- [🧪 测试](#-测试)
- [🗂️ API 概览](#️-api-概览)
- [📋 支持范围](#-支持范围)
- [🔬 算法参考](#-算法参考)
- [📝 许可证](#-许可证)

####

<br/>

</details>

## ✨ 特性

> \[!IMPORTANT\]
>
> **Star Us** — 你将第一时间收到 GitHub 的版本更新通知 \~ ⭐️

| | 功能 | 说明 |
|-|------|------|
| ♈ | **上升星座 (ASC)** | 基于恒星时 + 章动 + 真黄赤交角，支持全球坐标 |
| 🏠 | **宫位系统** | 16 种十二宫系统 + 独立 Gauquelin 36 扇区，含四轴与高纬度处理 |
| ☀️ | **太阳星座** | VSOP87D + FK5 修正 + 光行差 + 章动 |
| 🌙 | **月亮星座** | ELP-2000/82（120 项）+ 残差修正 + 章动 |
| 🪐 | **行星星座** | 水金火木土五大行星 — 光行时 + FK5 + 引力偏折 + 残差修正 |
| 🔭 | **外行星与虚点** | 天王星、海王星、冥王星、月交点与黑月莉莉丝（分级精度） |
| 🔗 | **相位与格局** | 单相位、完整相位网格、入/出相位、精确时刻、跨盘合盘与格局识别 |
| 🌅 | **升 · 落 · 中天** | 民用日升落事件、晨昏蒙影与子午中天 |
| ↩️ | **留与逆行** | 顺行/逆行留点与逆行区间 |
| 🏃 | **运动状态** | 每个天体的黄经速度与逆行标记 |
| 📊 | **批量本命盘** | 一次计算天体、ASC、宫位与四轴 |
| 🌐 | **城市数据库** | 33,000+ 全球城市坐标与时区（可选模块） |
| 🧵 | **线程安全** | 全面遵循 `Sendable` |
| 🚫 | **零依赖** | 纯 Swift，无第三方库 |
| ✅ | **分级精度** | 主要真实天体经本地验证；定义型计算点单独说明 |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📦 安装

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(name: "AstroCore", url: "https://github.com/wbx1-Ltd/AstroCore-Swift.git", from: "3.0.0"),
]
```

然后在 target 中添加依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AstroCore", package: "AstroCore"),                 // 核心天文计算
        .product(name: "AstroAstrology", package: "AstroCore"),            // 星座、宫位、星盘
        .product(name: "AstroCoreLocations", package: "AstroCore"),        // 可选城市检索
    ]
),
```

如果你的 App 已有城市/坐标数据，可以不引入可选城市模块：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AstroCore", package: "AstroCore"),
        .product(name: "AstroAstrology", package: "AstroCore"),
    ]
),
```

或在 Xcode 中：**文件 → 添加包依赖…** → 粘贴上方 URL。

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🚀 使用

`AstroCore` 提供底层天文计算原语；`AstroAstrology` 在其上提供星座、
宫位、Gauquelin 扇区、本命盘和相位。只要你已有坐标 (`GeoCoordinate`)
和时区 (`timeZoneIdentifier`)，两者都不依赖城市数据。

如果本地墙上时间落在夏令时回拨产生的重复小时内，请额外传入
`repeatedTimeResolution: .firstOccurrence` 或 `.lastOccurrence`，
显式指定要使用的真实时刻。

```swift
import AstroCore
import AstroAstrology
```

### ☀️ 太阳星座

```swift
let moment = try CivilMoment(
    year: 2000, month: 6, day: 21, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let sun = AstroCalculator.sunPosition(for: moment)
let sign = ZodiacSign(longitude: sun.longitude)
print(sign.name)                            // "Cancer"
print(sign.emoji)                           // "♋"
print(sun.longitude)                        // 90.406°（夏至）
print(sun.longitude - sign.startLongitude)  // 星座内 0.406°
```

### 🌙 月亮星座

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let moon = AstroCalculator.moonPosition(for: moment)
let sign = ZodiacSign(longitude: moon.longitude)
print(sign.name)            // "Scorpio"
print(sign.emoji)           // "♏"
print(moon.latitude)        // 5.17°（黄纬）
```

### 🪐 行星位置

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)

// 单颗行星
let venus = AstroCalculator.planetPosition(.venus, for: moment)
let venusSign = ZodiacSign(longitude: venus.longitude)
print("\(venusSign.emoji) Venus in \(venusSign.name)")  // "♐ Venus in Sagittarius"

// 支持的天体：.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn,
//            .uranus, .neptune, .pluto、月交点与 Lilith 变体
```

### ♈ 上升星座 (ASC)

```swift
let moment = try CivilMoment(
    year: 1990, month: 8, day: 15, hour: 14, minute: 30,
    timeZoneIdentifier: "America/New_York"
)
let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
let asc = try AstrologyCalculator.ascendant(for: moment, coordinate: coord)
print(asc.sign.name)             // "Sagittarius"
print(asc.eclipticLongitude)     // 240.93°
print(asc.degreeInSign)          // 0.93°
```

### 🏠 宫位系统

```swift
let houses = try AstrologyCalculator.houses(
    for: moment,
    coordinate: coord,
    system: .placidus,
    polarFallback: .porphyry
)

print(houses.requestedSystem.displayName)  // "Placidus"
print(houses.resolvedSystem.displayName)   // "Placidus"
print(houses.cusps[0].sign.name)           // 第一宫宫头所属星座
print(houses.angles.ascendant)             // ASC 黄经
print(houses.angles.midheaven)             // MC 黄经
```

支持的宫位系统：
`.equalASC`、`.equalMC`、`.wholeSign`、`.vehlow`、`.porphyry`、`.sripati`、
`.placidus`、`.koch`、`.alcabitius`、`.campanus`、`.regiomontanus`、
`.morinus`、`.topocentric`、`.horizontal`、`.meridian`、`.carter`

`HouseSystem.meridian` 是 Meridian / Axial Rotation / Zariel 的统一公开入口。

高纬度 fallback 策略：
`.porphyry`（默认）、`.equalASC`、`.wholeSign`、`.error`

独立的 Gauquelin 36 扇区模型：

```swift
let sectors = try AstrologyCalculator.gauquelinSectors(
    for: moment,
    coordinate: coord
)

print(sectors.sectors[0].number)                  // 1
print(sectors.sectors[0].eclipticLongitude)       // sector 1 = ASC
print(sectors.sectors[9].eclipticLongitude)       // sector 10 = MC
print(sectors.sectors[18].eclipticLongitude)      // sector 19 = DSC
print(sectors.sectors[27].eclipticLongitude)      // sector 28 = IC
```

v3 公开 API 暂不支持：
`Krusinski-Pisa-Goelzer`、`APC`、`Sunshine (Treindl)`、
`Sunshine (Makransky)`、`Pullen SD`、`Pullen SR`

### 📊 批量本命盘

```swift
let moment = try CivilMoment(
    year: 1990, month: 8, day: 15, hour: 14, minute: 30,
    timeZoneIdentifier: "America/New_York"
)
let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)

let natal = try AstrologyCalculator.natalPositions(
    for: moment,
    coordinate: coord,
    bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
    includeAscendant: true
)

// 上升星座
print("ASC: \(natal.ascendant!.sign.emoji) \(natal.ascendant!.sign.name)")

// 遍历所有天体
for (body, pos) in natal.bodies {
    let sign = ZodiacSign(longitude: pos.longitude)
    print("\(sign.emoji) \(body) in \(sign.name) \(pos.longitude - sign.startLongitude)°")
}
```

如果你还想一次拿到宫位和四轴，可以直接用：

```swift
let chart = try AstrologyCalculator.natalChart(
    for: moment,
    coordinate: coord,
    system: .placidus
)

print(chart.houses.angles.vertex ?? .nan)
print(chart.houses.cusps[9].eclipticLongitude)  // 第十宫宫头 / MC 象限
```

### 🌐 城市数据库（可选）

```swift
import AstroCoreLocations

let cities = CityIndex.shared

// 搜索城市
let results = cities.search("Tokyo", limit: 5)
for city in results {
    print("\(city.name), \(city.countryCode)")  // "Tokyo, JP"
    print("  \(city.latitude), \(city.longitude)")
    print("  \(city.timeZoneIdentifier)")       // "Asia/Tokyo"
}

// 直接获取 GeoCoordinate 用于计算
let tokyo = results.first!
let asc = try AstrologyCalculator.ascendant(for: moment, coordinate: tokyo.coordinate)
```

### 🔧 底层 API

```swift
// 儒略日
let jd = AstroCalculator.julianDayUT(for: moment)

// 地方恒星时（度）
let lst = AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: 139.65)

// 黄道十二宫
let sign = ZodiacSign.leo
print(sign.name)           // "Leo"
print(sign.emoji)          // "♌"
print(sign.startLongitude) // 120.0
print(sign.contains(longitude: 135.0))  // true
```

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🎯 精度

2000-01-01 12:00 UTC 各天体视黄经本地验证误差：

| | 天体 | 基线 | AstroCore | 误差 |
|-|------|-------------|-----------|------|
| ☀️ | 太阳 | 280.3689° | 280.3689° | **0.02″** |
| 🌙 | 月亮 | 223.3238° | 223.3239° | **0.51″** |
| ☿ | 水星 | 271.8893° | 271.8893° | **0.08″** |
| ♀️ | 金星 | 241.5658° | 241.5658° | **0.15″** |
| ♂️ | 火星 | 327.9633° | 327.9633° | **0.06″** |
| ♃ | 木星 | 25.2531° | 25.2531° | **0.14″** |
| ♄ | 土星 | 40.3956° | 40.3956° | **0.04″** |

> **上表核心天体在本地验证集中误差 < 1 角秒。**

当前入仓 CI 可证明 release 测试，以及
`ASTROCORE_ENABLE_BASELINE_VERIFICATION=1` 开启的 gated reference baseline。
更大范围但未入仓的历元扫测应视为本地验证数据，直到对应 fixture 纳入仓库。

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## ⚡ 性能

Release 模式，Apple Silicon（M-series）：

| 计算项 | 耗时 |
|--------|------|
| 上升星座 | **0.03 µs** |
| 宫位宫头（单系统） | **0.3–5.8 µs** |
| 太阳位置 | **9.3 µs** |
| 月亮位置 | **1.5 µs** |
| 单颗行星（水星–冥王星） | **34–166 µs** |
| 相位网格（10 天体，45 组） | **15 µs** |
| 跨盘合盘（7×7） | **9 µs** |
| 相位格局识别 | **27 µs** |
| 完整基础位置（7 天体 + ASC） | **620 µs** |
| 运动状态星盘（7 天体 + ASC） | **1.95 ms** |

> 默认基础位置吞吐量约 **1,600 张星盘/秒**。数据可通过 `swift test -c release --filter Benchmark` 复现。

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🧪 测试

| 指标 | 数值 |
|------|------|
| 测试用例 | **253** |
| 测试套件 | **39** |

验证方式（`swift test -c release`）：

- ✅ **本地验证基线** — 1800–2100 多历元验证，并按对象分级声明精度
- ✅ **至点与分点参考** — 2000 夏至、1990 春分、2024 冬至太阳黄经对照 fixture 校验
- ✅ **全球城市** — 纽约、伦敦、东京、柏林、悉尼的上升与本命回归
- ✅ **宫位系统** — 16 种系统覆盖宫头有效性、四轴对齐与高纬 fallback
- ✅ **Gauquelin 扇区** — 独立 36 扇区模型，覆盖顺时针编号与 baseline
- ✅ **极端边界** — 年份边界(1800/2100)、极地纬度、星座交界
- ✅ **回归基准** — 在 CI 和本地 release 校验中 gated 检查宫位、Gauquelin 扇区、相位、升落中天与留点

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🗂️ API 概览

### AstroCore（核心计算）

| 类型 | 说明 |
|------|------|
| `AstroCalculator` | 主入口 — 儒略日、太阳/月亮/行星位置、运动状态、导出坐标、光照度、时差、升落中天、留点与相位原语 |
| `CivilMoment` | 民用时间（年月日时分秒 + IANA 时区，必要时可显式指定重复小时的解析策略） |
| `RepeatedTimeResolution` | 夏令时回拨重复小时的解析策略：拒绝、第一次出现或最后一次出现 |
| `GeoCoordinate` | 地理坐标（纬度/经度范围校验） |
| `CelestialPosition` | 轻量天体位置（黄经、黄纬、可选距离） |
| `CelestialState` | 运动状态天体（位置 + 黄经速度/逆行） |
| `CelestialBody` | 天体枚举 — 太阳至冥王星、月交点与 Lilith 变体 |
| `EquatorialCoordinate` / `HorizontalCoordinate` | 导出的赤道坐标与地平（地心修正）坐标 |
| `StationKind` | 顺行 / 逆行 / 留 的分类 |
| `AstroError` | 类型化核心错误（坐标无效、年份越界、星历数据缺失等） |

### AstroAstrology（占星层）

| 类型 | 说明 |
|------|------|
| `AstrologyCalculator` | 占星主入口 — 黄道映射、上升、宫位、Gauquelin 扇区、本命盘/运动态、升落事件与晨昏蒙影、留与逆行、以及相位（网格、格局、合盘） |
| `ZodiacSign` | 黄道十二宫（名称、emoji、起始经度、`contains()`、`init(longitude:)`） |
| `AscendantResult` | 上升星座结果（黄经、星座、星座内度数、边界标记） |
| `NatalPositions` | 批量结果（可选 ASC + 天体字典） |
| `NatalStates` | 运动状态批量结果（可选 ASC + 天体状态字典） |
| `NatalChart` | 完整星盘结果（positions + houses + context） |
| `HouseSystem` | 16 种十二宫系统及其显示元数据 |
| `HouseResult` | 宫头、四轴、请求/实际系统等结果集合 |
| `HouseCusp` | 单个宫头（`1...12`）及其经度/星座信息 |
| `GauquelinResult` | 独立 36 扇区结果，复用同一组四轴 |
| `GauquelinSector` | 单个 Gauquelin 扇区边界（`1...36`，顺时针编号） |
| `Angles` | ASC / MC / DSC / IC 与可选 Vertex |
| `PolarFallback` | 极地纬度下宫位系统不可用时的 fallback 策略 |
| `AspectKind` / `AspectGrid` | 相位定义与匹配到的天体相位网格 |
| `Aspect` / `ChartAspect` / `CrossAspect` | 单条相位：容许度、入/出相位、是否精确 |
| `AspectPattern` / `AspectPatternKind` | 识别出的多体相位格局 |
| `ChartAngle` / `AspectParticipant` | 星盘四轴与相位参与者（天体或四轴） |
| `OrbPolicy` | 可配置的按相位/按天体容许度 |
| `RiseSetEvents` / `EventInstant` | 升落中天时刻，含极昼夜与晨昏状态 |
| `Station` | 单个天体的顺/逆行留点时刻 |
| `AstrologyError` | 类型化占星层错误（缺少坐标、高纬宫位错误、包装的核心错误等） |

### AstroCoreLocations（可选）

| 类型 | 说明 |
|------|------|
| `CityIndex` | 单例城市搜索引擎 |
| `CityRecord` | 城市记录（名称、国家代码、坐标、时区） |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📋 支持范围

| | 项目 | 范围 |
|-|------|------|
| 📆 | 年份 | 1800 — 2100（301 年） |
| 🪐 | 天体 | 太阳、月亮、水星、金星、火星、木星、土星、天王星、海王星、冥王星、月交点、Lilith 变体 |
| 🏠 | 宫位系统 | 16 种：Equal (ASC/MC)、Whole Sign、Vehlow、Porphyry、Sripati、Placidus、Koch、Alcabitius、Campanus、Regiomontanus、Morinus、Topocentric、Horizontal、Meridian / Axial Rotation、Carter |
| 📈 | Gauquelin 扇区 | 36 扇区统计模型，使用独立 API |
| 🖥️ | 平台 | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift | 6.0+ |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🔬 算法参考

| 来源 | 用途 |
|------|------|
| **Standard astronomical algorithms** | 儒略日、ΔT、恒星时、章动、上升星座公式 |
| **VSOP87D** | 行星日心黄道球坐标（完整级数） |
| **ELP-2000/82** | 月球黄经/黄纬（120 项截断级数） |
| **传统宫位几何方法** | Equal、Whole Sign、Porphyry、Sripati、semi-arc、great-circle 等宫位构造 |
| **IAU 1980 章动模型** | 63 项章动黄经/黄赤交角修正 |
| **平黄赤交角多项式** | 10 阶黄赤交角级数 |
| **Standard ΔT model (2006)** | ΔT 分段多项式（1800–2100） |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📝 许可证

Copyright &copy; 2026-present [Babywbx][profile-link].<br/>
本项目基于 [MIT](./LICENSE) 许可证发布。

`AstroCoreLocations` 打包派生城市数据。如果你要分发或在产品中展示这份数据，
发版前请同步检查归属要求。

<!-- LINK GROUP -->

[back-to-top]: https://img.shields.io/badge/-BACK_TO_TOP-151515?style=flat-square
[github-contributors-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/graphs/contributors
[github-contributors-shield]: https://img.shields.io/github/contributors/wbx1-Ltd/AstroCore-Swift?color=c4f042&labelColor=black&style=flat-square
[github-forks-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/network/members
[github-forks-shield]: https://img.shields.io/github/forks/wbx1-Ltd/AstroCore-Swift?color=8ae8ff&labelColor=black&style=flat-square
[github-issues-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/issues
[github-issues-shield]: https://img.shields.io/github/issues/wbx1-Ltd/AstroCore-Swift?color=ff80eb&labelColor=black&style=flat-square
[github-license-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/blob/main/LICENSE
[github-license-shield]: https://img.shields.io/github/license/wbx1-Ltd/AstroCore-Swift?color=white&labelColor=black&style=flat-square
[github-release-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/releases
[github-stars-link]: https://github.com/wbx1-Ltd/AstroCore-Swift/stargazers
[github-stars-shield]: https://img.shields.io/github/stars/wbx1-Ltd/AstroCore-Swift?color=ffcb47&labelColor=black&style=flat-square
[profile-link]: https://github.com/babywbx
