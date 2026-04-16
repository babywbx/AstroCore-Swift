<div align="center"><a name="readme-top"></a>

# AstroCore

A high-precision Western astrology computation library in pure Swift, covering 1800–2100.<br/>
Sub-arcsecond accuracy for all bodies, zero dependencies, thread-safe.

[简体中文](./README.zh-CN.md) · [Report Issue][github-issues-link] · [Releases][github-release-link]

<!-- SHIELD GROUP -->

[![][github-stars-shield]][github-stars-link]
[![][github-forks-shield]][github-forks-link]
[![][github-issues-shield]][github-issues-link]
[![][github-license-shield]][github-license-link]<br/>
[![][github-contributors-shield]][github-contributors-link]

</div>

<details>
<summary><kbd>Table of Contents</kbd></summary>

#### TOC

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🚀 Usage](#-usage)
  - [☀️ Sun Sign](#️-sun-sign)
  - [🌙 Moon Sign](#-moon-sign)
  - [🪐 Planet Positions](#-planet-positions)
  - [♈ Ascendant (Rising Sign)](#-ascendant-rising-sign)
  - [📊 Batch Natal Chart](#-batch-natal-chart)
  - [🌐 City Database (Optional)](#-city-database-optional)
  - [🔧 Low-Level API](#-low-level-api)
- [🎯 Precision](#-precision)
- [⚡ Performance](#-performance)
- [🧪 Testing](#-testing)
- [🗂️ API Reference](#️-api-reference)
- [📋 Supported Range](#-supported-range)
- [🔬 Algorithms](#-algorithms)
- [📝 License](#-license)

####

<br/>

</details>

## ✨ Features

> \[!IMPORTANT\]
>
> **Star Us** — you will receive all release notifications from GitHub without any delay \~ ⭐️

| | Feature | Description |
|-|---------|-------------|
| ♈ | **Ascendant (ASC)** | Sidereal time + nutation + true obliquity, global coordinates |
| ☀️ | **Sun Sign** | VSOP87D + FK5 correction + aberration + nutation |
| 🌙 | **Moon Sign** | ELP-2000/82 (120 terms) + residual correction + nutation |
| 🪐 | **Planet Signs** | Mercury through Saturn — light-time + FK5 + gravitational deflection + residual correction |
| 📊 | **Batch Natal Chart** | Compute ASC + all body positions in one call |
| 🌐 | **City Database** | 33,000+ global cities with coordinates & timezones (optional module) |
| 🧵 | **Thread-Safe** | Full `Sendable` conformance |
| 🚫 | **Zero Dependencies** | Pure Swift, no third-party libraries |
| ✅ | **Sub-Arcsecond** | All bodies verified < 1″ against JPL Horizons (DE440/441) |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wbx1-Ltd/AstroCore-Swift.git", from: "1.2.0"),
]
```

Then add as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        "AstroCore",              // ~1.7 MB — core computation
        "AstroCoreLocations",     // +2 MB on top (~3.7 MB total)
    ]
),
```

If your app already has city/coordinate data, import only the core:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AstroCore"]  // only ~1.7 MB
),
```

Or in Xcode: **File → Add Package Dependencies…** → paste the URL above.

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🚀 Usage

`AstroCore` only requires coordinates (`GeoCoordinate`) and a timezone (`timeZoneIdentifier`) — no city data needed.

```swift
import AstroCore
```

### ☀️ Sun Sign

```swift
let moment = try CivilMoment(
    year: 2000, month: 6, day: 21, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let sun = AstroCalculator.sunPosition(for: moment)
print(sun.sign.name)        // "Cancer"
print(sun.sign.emoji)       // "♋"
print(sun.longitude)        // 90.406° (summer solstice)
print(sun.degreeInSign)     // 0.406°
```

### 🌙 Moon Sign

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let moon = AstroCalculator.moonPosition(for: moment)
print(moon.sign.name)       // "Scorpio"
print(moon.sign.emoji)      // "♏"
print(moon.latitude)        // 5.17° (ecliptic latitude)
```

### 🪐 Planet Positions

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)

// Single planet
let venus = AstroCalculator.planetPosition(.venus, for: moment)
print("\(venus.sign.emoji) Venus in \(venus.sign.name)")  // "♐ Venus in Sagittarius"

// Supported bodies: .sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn
```

### ♈ Ascendant (Rising Sign)

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

### 📊 Batch Natal Chart

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

// Ascendant
print("ASC: \(natal.ascendant!.sign.emoji) \(natal.ascendant!.sign.name)")

// All body positions
for (body, pos) in natal.bodies {
    print("\(pos.sign.emoji) \(body) in \(pos.sign.name) \(pos.degreeInSign)°")
}
```

### 🌐 City Database (Optional)

```swift
import AstroCoreLocations

let cities = CityIndex.shared

// Search cities
let results = cities.search("Tokyo", limit: 5)
for city in results {
    print("\(city.name), \(city.countryCode)")  // "Tokyo, JP"
    print("  \(city.latitude), \(city.longitude)")
    print("  \(city.timeZoneIdentifier)")       // "Asia/Tokyo"
}

// Use GeoCoordinate directly for calculations
let tokyo = results.first!
let asc = try AstroCalculator.ascendant(for: moment, coordinate: tokyo.coordinate)
```

### 🔧 Low-Level API

```swift
// Julian Day
let jd = AstroCalculator.julianDayUT(for: moment)

// Local Apparent Sidereal Time (degrees)
let lst = AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: 139.65)

// Zodiac signs
let sign = ZodiacSign.leo
print(sign.name)           // "Leo"
print(sign.emoji)          // "♌"
print(sign.startLongitude) // 120.0
print(sign.contains(longitude: 135.0))  // true
```

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🎯 Precision

Verified against **JPL Horizons** (DE440/441) at 2000-01-01 12:00 UTC, apparent ecliptic longitude:

| | Body | JPL Horizons | AstroCore | Error |
|-|------|-------------|-----------|-------|
| ☀️ | Sun | 280.3689° | 280.3689° | **0.02″** |
| 🌙 | Moon | 223.3238° | 223.3239° | **0.51″** |
| ☿ | Mercury | 271.8893° | 271.8893° | **0.08″** |
| ♀️ | Venus | 241.5658° | 241.5658° | **0.15″** |
| ♂️ | Mars | 327.9633° | 327.9633° | **0.06″** |
| ♃ | Jupiter | 25.2531° | 25.2531° | **0.14″** |
| ♄ | Saturn | 40.3956° | 40.3956° | **0.04″** |

> **All bodies < 1 arcsecond.**

Cross-validated across 750+ epochs spanning 1850–2100.

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## ⚡ Performance

Release build, Apple Silicon (M-series):

| Computation | Time |
|-------------|------|
| Ascendant | **0.03 µs** |
| Moon position | **0.9 µs** |
| Sun position | **9 µs** |
| Single planet | **55–170 µs** |
| Full natal chart (7 bodies + ASC) | **630 µs** |

> Throughput: ~**1,600 charts/sec**.

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🧪 Testing

| Metric | Value |
|--------|-------|
| Test functions | **122** |
| Test suites | **23** |

Validation:

- ✅ **JPL Horizons (DE440/441)** — multi-epoch sub-arcsecond verification, 1850–2100
- ✅ **Solstice cross-validation** — 2000 summer & 2024 winter solstice error < 1.5″
- ✅ **8 global cities** — NYC, London, Tokyo, Berlin, Sydney, Mumbai, LA, Helsinki
- ✅ **Edge cases** — year boundaries (1800/2100), polar latitudes, sign boundaries
- ✅ **Regression baselines** — automatic numerical drift detection (< 10⁻¹⁰°)

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🗂️ API Reference

### AstroCore (Core Computation)

| Type | Description |
|------|-------------|
| `AstroCalculator` | Main entry — Sun/Moon/planet/ascendant/natal chart |
| `CivilMoment` | Civil time (year/month/day/hour/minute/second + IANA timezone) |
| `GeoCoordinate` | Geographic coordinate with extreme latitude validation |
| `CelestialBody` | Body enum — `.sun`, `.moon`, `.mercury`, `.venus`, `.mars`, `.jupiter`, `.saturn` |
| `ZodiacSign` | 12 zodiac signs with name, emoji, start longitude, `contains()` |
| `CelestialPosition` | Body position (ecliptic longitude/latitude, sign, degree in sign) |
| `AscendantResult` | Ascendant (ecliptic longitude, sign, sidereal time, obliquity) |
| `NatalPositions` | Batch result (ascendant + body dictionary) |
| `AstroError` | Typed errors (invalid coordinate, unsupported year, extreme latitude) |

### AstroCoreLocations (Optional)

| Type | Description |
|------|-------------|
| `CityIndex` | Singleton city search engine |
| `CityRecord` | City record (name, country code, coordinate, timezone) |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📋 Supported Range

| | Item | Range |
|-|------|-------|
| 📆 | Year range | 1800 — 2100 (301 years) |
| 🪐 | Bodies | Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn |
| 🖥️ | Platforms | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift | 6.0+ |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🔬 Algorithms

| Source | Usage |
|--------|-------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | Julian Day, ΔT, sidereal time, nutation, ascendant formulas |
| **VSOP87D** (Bretagnon & Francou, 1988) | Heliocentric ecliptic coordinates (full series) |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | Lunar longitude/latitude (120-term truncated series) |
| **IAU 1980 Nutation Model** | 63-term nutation in longitude/obliquity |
| **Laskar (1986)** | Mean obliquity 10th-degree polynomial |
| **Espenak & Meeus (2006)** | ΔT piecewise polynomials (1800–2100) |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📝 License

Copyright &copy; 2026-present [Babywbx][profile-link].<br/>
This project is [MIT](./LICENSE) licensed.

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
