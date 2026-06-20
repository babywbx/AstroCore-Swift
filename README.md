<div align="center"><a name="readme-top"></a>

# AstroCore

A high-precision Western astrology computation library in pure Swift, covering 1800–2100.<br/>
Tiered local-validation accuracy, zero runtime dependencies, thread-safe.

> This README describes the v3 package split:
> `AstroCore` for low-level astronomy, `AstroAstrology` for astrology models,
> and `AstroCoreLocations` for optional city lookup data.

[简体中文](./README.zh-CN.md) · [Report Issue][github-issues-link] · [Changelog](./CHANGELOG.md) · [Releases][github-release-link]

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
  - [🏠 House Systems](#-house-systems)
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
| 🏠 | **House Systems** | 16 twelve-house systems plus an independent 36-sector Gauquelin model, with angles and polar-latitude handling |
| ☀️ | **Sun Sign** | VSOP87D + FK5 correction + aberration + nutation |
| 🌙 | **Moon Sign** | ELP-2000/82 (120 terms) + residual correction + nutation |
| 🪐 | **Planet Signs** | Mercury through Saturn — light-time + FK5 + gravitational deflection + residual correction |
| 🔭 | **Outer Bodies** | Uranus, Neptune, Pluto, lunar nodes, and Black Moon Lilith (tiered precision) |
| 🔗 | **Aspects & Patterns** | Single-pair, full grids, applying/separating, exact moments, cross-chart synastry, and pattern detection |
| 🌅 | **Rise · Set · Transit** | Civil-day rise/set events, twilight overlays, and meridian transits |
| ↩️ | **Stations & Retrograde** | Direct/retrograde stations and retrograde intervals |
| 🏃 | **Motion States** | Per-body longitude speed and retrograde flags |
| 📊 | **Batch Natal Chart** | Compute planets, ASC, houses, and angles in one call |
| 🌐 | **City Database** | 33,000+ global cities with coordinates & timezones (optional module) |
| 🧵 | **Thread-Safe** | Full `Sendable` conformance |
| 🚫 | **Zero Dependencies** | No third-party packages — pure Swift on Apple's Foundation + Accelerate |
| ✅ | **Tiered Precision** | Primary real bodies are locally validated; definition points are documented separately |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(name: "AstroCore", url: "https://github.com/wbx1-Ltd/AstroCore-Swift.git", from: "3.0.0"),
]
```

Then add as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AstroCore", package: "AstroCore"),                 // core astronomy
        .product(name: "AstroAstrology", package: "AstroCore"),            // signs, houses, charts
        .product(name: "AstroCoreLocations", package: "AstroCore"),        // optional city lookup
    ]
),
```

If your app already has city/coordinate data, skip the optional locations product:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AstroCore", package: "AstroCore"),
        .product(name: "AstroAstrology", package: "AstroCore"),
    ]
),
```

Or in Xcode: **File → Add Package Dependencies…** → paste the URL above.

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🚀 Usage

`AstroCore` provides the low-level astronomy primitives. `AstroAstrology`
builds signs, houses, Gauquelin sectors, natal charts, and aspects on top of
those primitives. Neither requires city data when you already have coordinates
(`GeoCoordinate`) and a timezone (`timeZoneIdentifier`).

If a local wall-clock time falls inside a DST fall-back repeat hour, pass
`repeatedTimeResolution: .firstOccurrence` or `.lastOccurrence` to select the
exact instant explicitly.

```swift
import AstroCore
import AstroAstrology
```

### ☀️ Sun Sign

```swift
let moment = try CivilMoment(
    year: 2000, month: 6, day: 21, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let sun = AstroCalculator.sunPosition(for: moment)
let sign = ZodiacSign(longitude: sun.longitude)
print(sign.name)                            // "Cancer"
print(sign.emoji)                           // "♋"
print(sun.longitude)                        // 90.406° (summer solstice)
print(sun.longitude - sign.startLongitude)  // 0.406° into the sign
```

### 🌙 Moon Sign

```swift
let moment = try CivilMoment(
    year: 2000, month: 1, day: 1, hour: 12, minute: 0,
    timeZoneIdentifier: "UTC"
)
let moon = AstroCalculator.moonPosition(for: moment)
let sign = ZodiacSign(longitude: moon.longitude)
print(sign.name)            // "Scorpio"
print(sign.emoji)           // "♏"
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
let venusSign = ZodiacSign(longitude: venus.longitude)
print("\(venusSign.emoji) Venus in \(venusSign.name)")  // "♐ Venus in Sagittarius"

// Bodies: .sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn,
//         .uranus, .neptune, .pluto, lunar nodes, and Lilith variants
```

### ♈ Ascendant (Rising Sign)

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

### 🏠 House Systems

```swift
let houses = try AstrologyCalculator.houses(
    for: moment,
    coordinate: coord,
    system: .placidus,
    polarFallback: .porphyry
)

print(houses.requestedSystem.displayName)  // "Placidus"
print(houses.resolvedSystem.displayName)   // "Placidus"
print(houses.cusps[0].sign.name)           // House 1 cusp sign
print(houses.angles.ascendant)             // ASC longitude
print(houses.angles.midheaven)             // MC longitude
```

Supported systems:
`.equalASC`, `.equalMC`, `.wholeSign`, `.vehlow`, `.porphyry`, `.sripati`,
`.placidus`, `.koch`, `.alcabitius`, `.campanus`, `.regiomontanus`,
`.morinus`, `.topocentric`, `.horizontal`, `.meridian`, `.carter`

`HouseSystem.meridian` is the published API for Meridian / Axial Rotation /
Zariel houses.

Polar fallback strategies:
`.porphyry` (default), `.equalASC`, `.wholeSign`, `.error`

Independent Gauquelin sectors (36-sector model):

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

Not part of the v3 public API yet:
`Krusinski-Pisa-Goelzer`, `APC`, `Sunshine (Treindl)`,
`Sunshine (Makransky)`, `Pullen SD`, `Pullen SR`

### 📊 Batch Natal Chart

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

// Ascendant
print("ASC: \(natal.ascendant!.sign.emoji) \(natal.ascendant!.sign.name)")

// All body positions
for (body, pos) in natal.bodies {
    let sign = ZodiacSign(longitude: pos.longitude)
    print("\(sign.emoji) \(body) in \(sign.name) \(pos.longitude - sign.startLongitude)°")
}
```

If you also want houses and angles in the same response:

```swift
let chart = try AstrologyCalculator.natalChart(
    for: moment,
    coordinate: coord,
    system: .placidus
)

print(chart.houses.angles.vertex ?? .nan)
print(chart.houses.cusps[9].eclipticLongitude)  // House 10 cusp / MC sector
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
let asc = try AstrologyCalculator.ascendant(for: moment, coordinate: tokyo.coordinate)
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

Validated at 2000-01-01 12:00 UTC, apparent ecliptic longitude:

| | Body | Baseline | AstroCore | Error |
|-|------|-------------|-----------|-------|
| ☀️ | Sun | 280.3689° | 280.3689° | **0.02″** |
| 🌙 | Moon | 223.3238° | 223.3239° | **0.51″** |
| ☿ | Mercury | 271.8893° | 271.8893° | **0.08″** |
| ♀️ | Venus | 241.5658° | 241.5658° | **0.15″** |
| ♂️ | Mars | 327.9633° | 327.9633° | **0.06″** |
| ♃ | Jupiter | 25.2531° | 25.2531° | **0.14″** |
| ♄ | Saturn | 40.3956° | 40.3956° | **0.04″** |

> **Listed core bodies are < 1 arcsecond in the local validation set.**

The committed CI proves the checked release tests plus gated reference baselines
enabled by `ASTROCORE_ENABLE_BASELINE_VERIFICATION=1`. Broader unpublished
epoch sweeps should be treated as local validation data until their fixtures are
checked into the repository.

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## ⚡ Performance

Release build, Apple Silicon (M-series). VSOP ephemeris evaluation is vectorized with Apple's Accelerate.

| Computation | Time |
|-------------|------|
| Ascendant | **0.03 µs** |
| House cusps (per system) | **0.3–6 µs** |
| Sun position | **4.6 µs** |
| Moon position | **1.6 µs** |
| Single planet (Mercury–Pluto) | **17–55 µs** |
| Aspect grid (10 bodies, 45 pairs) | **15 µs** |
| Cross-chart synastry (7×7) | **9 µs** |
| Aspect pattern detection | **27 µs** |
| Full natal positions (7 bodies + ASC) | **175 µs** |
| Motion-rich natal states (7 bodies + ASC) | **485 µs** |

> Default chart throughput: ~**5,700 charts/sec**. Numbers reproduce via `swift test -c release --filter Benchmark`.

### vs. v2.0.0

v3 vectorizes VSOP ephemeris evaluation with Accelerate, so computations shared with v2 are markedly faster — at identical accuracy (every regression baseline still passes):

| Computation | v2.0.0 | v3.0.0 | Speedup |
|-------------|--------|--------|---------|
| Sun position | 9.4 µs | 4.6 µs | **2.0×** |
| Mercury position | 164 µs | 55 µs | **3.0×** |
| Saturn position | 139 µs | 49 µs | **2.8×** |
| Full natal positions (7 bodies + ASC) | 616 µs | 175 µs | **3.5×** |
| Natal throughput | ~1,620 charts/sec | ~5,700 charts/sec | **3.5×** |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🧪 Testing

| Metric | Value |
|--------|-------|
| Test cases | **253** |
| Test suites | **39** |

Validation (`swift test -c release`):

- ✅ **Local validation baselines** — multi-epoch verification with tiered accuracy claims, 1800–2100
- ✅ **Solstice & equinox references** — 2000 summer solstice, 1990 spring equinox, and 2024 winter solstice Sun longitudes checked against fixtures
- ✅ **Global cities** — ascendant & natal regression across New York, London, Tokyo, Berlin, and Sydney
- ✅ **House systems** — 16 systems checked for cusp validity, angle alignment, and polar fallback behavior
- ✅ **Gauquelin sectors** — independent 36-sector model with clockwise numbering and baseline coverage
- ✅ **Edge cases** — year boundaries (1800/2100), polar latitudes, sign boundaries
- ✅ **Regression baselines** — gated reference checks in CI and local release verification for houses, Gauquelin sectors, aspects, rise/set/transit, and stations

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🗂️ API Reference

### AstroCore (Core Computation)

| Type | Description |
|------|-------------|
| `AstroCalculator` | Main entry — Julian day, Sun/Moon/planet positions, motion states, derived coordinates, illumination, equation of time, rise/set/transit, stations, and aspect primitives |
| `CivilMoment` | Civil time (year/month/day/hour/minute/second + IANA timezone, with explicit repeated-time resolution when needed) |
| `RepeatedTimeResolution` | DST fall-back ambiguity policy: reject, first occurrence, or last occurrence |
| `GeoCoordinate` | Geographic coordinate with range-checked latitude and longitude |
| `CelestialPosition` | Lightweight body position (ecliptic longitude/latitude + optional distance) |
| `CelestialState` | Motion-rich body state (position + longitude speed/retrograde) |
| `CelestialBody` | Body enum — Sun through Pluto plus lunar nodes and Lilith variants |
| `EquatorialCoordinate` / `HorizontalCoordinate` | Derived equatorial and topocentric horizontal frames |
| `StationKind` | Direct / retrograde / stationary classification |
| `AstroError` | Typed core errors (invalid coordinate, unsupported year, missing ephemeris data) |

### AstroAstrology (Astrology Layer)

| Type | Description |
|------|-------------|
| `AstrologyCalculator` | Main astrology entry — zodiac mapping, ascendant, houses, Gauquelin sectors, natal charts/states, rise/set events & twilight, stations & retrograde, and aspects (grids, patterns, synastry) |
| `ZodiacSign` | 12 zodiac signs with name, emoji, start longitude, `contains()`, and `init(longitude:)` |
| `AscendantResult` | Ascendant (ecliptic longitude, sign, degree in sign, boundary flag) |
| `NatalPositions` | Batch result (optional ascendant + body dictionary) |
| `NatalStates` | Motion-rich batch result (optional ascendant + body state dictionary) |
| `NatalChart` | Full chart payload (positions + houses + context) |
| `HouseSystem` | 16 supported 12-house systems with display metadata |
| `HouseResult` | Cusps + angles + requested/resolved system metadata |
| `HouseCusp` | One cusp entry (`1...12`) with longitude/sign metadata |
| `GauquelinResult` | Independent 36-sector result with shared chart angles |
| `GauquelinSector` | One clockwise Gauquelin sector boundary (`1...36`) |
| `Angles` | ASC / MC / DSC / IC and optional vertex |
| `PolarFallback` | Fallback strategy when a house system is undefined at polar latitudes |
| `AspectKind` / `AspectGrid` | Aspect definitions and matched body-body aspect grids |
| `Aspect` / `ChartAspect` / `CrossAspect` | One matched aspect: orb, applying/separating, exactness |
| `AspectPattern` / `AspectPatternKind` | Detected multi-body aspect patterns |
| `ChartAngle` / `AspectParticipant` | Chart angles and aspect participants (body or angle) |
| `OrbPolicy` | Configurable per-aspect / per-body orb allowances |
| `RiseSetEvents` / `EventInstant` | Rise/set/transit instants with circumpolar and twilight state |
| `Station` | A direct/retrograde station instant for a body |
| `AstrologyError` | Typed astrology-layer errors (missing coordinate, polar fallback error, wrapped core errors) |

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
| 🪐 | Bodies | Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, lunar nodes, Lilith variants |
| 🏠 | House systems | 16 systems: Equal (ASC/MC), Whole Sign, Vehlow, Porphyry, Sripati, Placidus, Koch, Alcabitius, Campanus, Regiomontanus, Morinus, Topocentric, Horizontal, Meridian / Axial Rotation, Carter |
| 📈 | Gauquelin sectors | 36-sector statistical model via dedicated API |
| 🖥️ | Platforms | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift | 6.0+ |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 🔬 Algorithms

| Source | Usage |
|--------|-------|
| **Standard astronomical algorithms** | Julian Day, ΔT, sidereal time, nutation, ascendant formulas |
| **VSOP87D** | Heliocentric ecliptic coordinates (full series) |
| **ELP-2000/82** | Lunar longitude/latitude (120-term truncated series) |
| **Classical house-system geometry** | Equal, Whole Sign, Porphyry, Sripati, semi-arc, and great-circle house constructions |
| **IAU 1980 Nutation Model** | 63-term nutation in longitude/obliquity |
| **Mean obliquity polynomial** | 10th-degree obliquity series |
| **Standard ΔT model (2006)** | ΔT piecewise polynomials (1800–2100) |

<div align="right">

[![][back-to-top]](#readme-top)

</div>

## 📝 License

Copyright &copy; 2026-present [Babywbx][profile-link].<br/>
This project is [MIT](./LICENSE) licensed.

`AstroCoreLocations` bundles derived city data. If you redistribute or surface the
packaged dataset, review the attribution requirements before release.

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
[profile-link]: https://github.com/wbx1-Ltd
