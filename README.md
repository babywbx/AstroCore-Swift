# 🔭 AstroCore

> **纯 Swift 实现的高精度西洋占星天文计算库，覆盖 1800–2100 年。**

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/babywbx/AstroCore-Swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.en.md)

**AstroCore** 从天文算法第一性原理出发，计算上升星座（ASC）、太阳/月亮/行星星座。基于 Jean Meeus《Astronomical Algorithms》实现完整的 VSOP87D 行星星历、ELP-2000/82 月球位置、IAU 1980 章动模型，精度经 JPL Horizons 验证达到角秒级别。

---

## ✨ 特点

| | 功能 | 说明 |
|-|------|------|
| ♈ | **上升星座 (ASC)** | 基于恒星时 + 章动 + 真黄赤交角，支持全球坐标 |
| ☀️ | **太阳星座** | VSOP87D + FK5 修正 + 光行差 + 章动 |
| 🌙 | **月亮星座** | ELP-2000/82（120 项） + 章动修正 |
| 🪐 | **行星星座** | 水金火木土五大行星，含光行时修正 |
| 📊 | **批量本命盘** | 一次计算 ASC + 全部天体位置 |
| 🌐 | **城市数据库** | 33,000+ 全球城市坐标与时区（可选模块） |
| 🧵 | **线程安全** | 全面遵循 `Sendable` |
| 🚫 | **零依赖** | 纯 Swift，无第三方库 |
| ✅ | **精度验证** | 经 JPL Horizons 天文台数据验证 |

---

## 📦 安装

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/babywbx/AstroCore-Swift.git", from: "1.0.0"),
]
```

然后在 target 中添加依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        "AstroCore",
        "AstroCoreLocations",  // 可选：城市坐标数据库
    ]
),
```

或在 Xcode 中：**文件 → 添加包依赖…** → 粘贴上方 URL。

---

## 🚀 使用

```swift
import AstroCore
```

### ☀️ 太阳星座

```swift
let moment = try CivilMoment(
    year: 2000, month: 6, day: 21, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let sun = try AstroCalculator.sunPosition(for: moment)
print(sun.sign.name)        // "Cancer"
print(sun.sign.emoji)       // "♋"
print(sun.longitude)        // 90.406° (夏至)
print(sun.degreeInSign)     // 0.406°
```

### 🌙 月亮星座

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let moon = try AstroCalculator.moonPosition(for: moment)
print(moon.sign.name)       // "Scorpio"
print(moon.sign.emoji)      // "♏"
print(moon.latitude)        // 5.17° (黄纬)
```

### 🪐 行星位置

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)

// 单颗行星
let venus = try AstroCalculator.planetPosition(.venus, for: moment)
print("\(venus.sign.emoji) Venus in \(venus.sign.name)")  // "♐ Venus in Sagittarius"

// 支持的天体：.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn
```

### ♈ 上升星座 (ASC)

```swift
let moment = try CivilMoment(
    year: 1990, month: 8, day: 15, hour: 14, minute: 30,
    timeZoneIdentifier: "America/New_York"
)
let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
let asc = try AstroCalculator.ascendant(for: moment, coordinate: coord)
print(asc.sign.name)             // "Sagittarius"
print(asc.eclipticLongitude)     // 240.93°
print(asc.degreeInSign)          // 0.93°
```

### 📊 批量本命盘

```swift
let moment = try CivilMoment(
    year: 1990, month: 8, day: 15, hour: 14, minute: 30,
    timeZoneIdentifier: "America/New_York"
)
let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)

let natal = try AstroCalculator.natalPositions(
    for: moment,
    coordinate: coord,
    bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
    includeAscendant: true
)

// 上升星座
print("ASC: \(natal.ascendant!.sign.emoji) \(natal.ascendant!.sign.name)")

// 遍历所有天体
for (body, pos) in natal.bodies {
    print("\(pos.sign.emoji) \(body) in \(pos.sign.name) \(pos.degreeInSign)°")
}
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

// 热门城市
let popular = cities.popularCities(limit: 10)

// 直接获取 GeoCoordinate 用于计算
let tokyo = results.first!
let asc = try AstroCalculator.ascendant(for: moment, coordinate: tokyo.coordinate)
```

### 🔧 底层 API

```swift
// 儒略日
let jd = try AstroCalculator.julianDayUT(for: moment)

// 地方恒星时（度）
let lst = try AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: 139.65)

// 黄道十二宫
let sign = ZodiacSign.leo
print(sign.name)           // "Leo"
print(sign.emoji)          // "♌"
print(sign.startLongitude) // 120.0
print(sign.contains(longitude: 135.0))  // true
```

---

## 🎯 精度

经 **JPL Horizons**（DE440/441 星历）验证，2000-01-01 12:00 UTC 各天体视黄经误差：

| | 天体 | JPL Horizons | AstroCore | 误差 |
|-|------|-------------|-----------|------|
| ☀️ | 太阳 | 280.3689° | 280.369° | **0.36″** |
| 🌙 | 月亮 | 223.3238° | 223.324° | **0.73″** |
| ☿ | 水星 | 271.8893° | 271.895° | **20.6″** |
| ♀️ | 金星 | 241.5658° | 241.570° | **15.2″** |
| ♂️ | 火星 | 327.9633° | 327.967° | **13.3″** |
| ♃ | 木星 | 25.2531° | 25.252° | **3.9″** |
| ♄ | 土星 | 40.3956° | 40.393° | **9.5″** |

> 全部天体误差 < 1 角分。太阳和月亮精度优于 1 角秒。

### 🧪 测试覆盖

| 指标 | 数值 |
|------|------|
| 测试函数 | **93** |
| 测试套件 | **20** |

验证来源：

- ✅ **JPL Horizons (DE440/441)** — 太阳/月亮/行星位置角秒级验证
- ✅ **至日交叉验证** — 2000 夏至、2024 冬至误差 < 1.5″
- ✅ **全球 8 城市上升星座** — 纽约、伦敦、东京、柏林等
- ✅ **极端边界** — 年份边界(1800/2100)、极地纬度、星座交界

---

## 🗂️ API 概览

### AstroCore（核心计算）

| 类型 | 说明 |
|------|------|
| `AstroCalculator` | 主入口 — 太阳/月亮/行星/上升星座/本命盘计算 |
| `CivilMoment` | 民用时间（年月日时分秒 + IANA 时区） |
| `GeoCoordinate` | 地理坐标（纬度/经度），含极端纬度验证 |
| `CelestialBody` | 天体枚举（日、月、水、金、火、木、土） |
| `ZodiacSign` | 黄道十二宫枚举（含名称、emoji、起始经度） |
| `CelestialPosition` | 天体位置结果（黄经、黄纬、星座、度数） |
| `AscendantResult` | 上升星座结果（黄经、星座、恒星时、黄赤交角） |
| `NatalPositions` | 批量结果（上升 + 天体字典） |
| `AstroError` | 类型化错误（坐标无效、年份越界、极端纬度等） |

### AstroCoreLocations（可选城市数据）

| 类型 | 说明 |
|------|------|
| `CityIndex` | 单例城市搜索引擎（search / popularCities / city(forID:)） |
| `CityRecord` | 城市记录（名称、坐标、时区、人口、本地化名称） |

---

## 📋 支持范围

| | 项目 | 范围 |
|-|------|------|
| 📆 | 年份 | 1800 — 2100（301 年） |
| 🪐 | 天体 | 太阳、月亮、水星、金星、火星、木星、土星 |
| 🖥️ | 平台 | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift | 6.0+ |

---

## 🔬 算法参考

| 来源 | 用途 |
|------|------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | 儒略日、ΔT、恒星时、章动、上升星座公式 |
| **VSOP87D** (Bretagnon & Francou, 1988) | 行星日心黄道球坐标（完整级数） |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | 月球黄经/黄纬（120 项截断级数） |
| **IAU 1980 章动模型** | 63 项章动黄经/黄赤交角修正 |
| **Laskar (1986)** | 平黄赤交角 10 阶多项式 |
| **Espenak & Meeus (2006)** | ΔT 分段多项式（1800–2100） |
| **JPL Horizons (DE440/441)** | 验证数据集 |

---

## 📄 许可

[MIT License](LICENSE) © 2026 [Babywbx](https://github.com/babywbx)
