# 🔭 AstroCore

> **A high-precision Western astrology computation library in pure Swift, covering 1800–2100.**

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/babywbx/AstroCore-Swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[中文](README.md)

**AstroCore** computes Ascendant (Rising Sign), Sun/Moon/planet signs from astronomical first principles. It implements full VSOP87D planetary ephemerides, ELP-2000/82 lunar positions, and IAU 1980 nutation, all verified against JPL Horizons to sub-arcminute precision.

---

## ✨ Features

| | Feature | Description |
|-|---------|-------------|
| ♈ | **Ascendant (ASC)** | Sidereal time + nutation + true obliquity, global coordinates |
| ☀️ | **Sun Sign** | VSOP87D + FK5 correction + aberration + nutation |
| 🌙 | **Moon Sign** | ELP-2000/82 (120 terms) + nutation correction |
| 🪐 | **Planet Signs** | Mercury, Venus, Mars, Jupiter, Saturn with light-time correction |
| 📊 | **Batch Natal Chart** | Compute ASC + all body positions in one call |
| 🌐 | **City Database** | 33,000+ global cities with coordinates & timezones (compact English dataset, optional) |
| 🧵 | **Thread-safe** | Full `Sendable` conformance |
| 🚫 | **Zero Dependencies** | Pure Swift, no third-party libraries |
| ✅ | **Verified Accuracy** | Validated against JPL Horizons ephemeris |

---

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/babywbx/AstroCore-Swift.git", from: "1.1.0"),
]
```

Then add as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        "AstroCore",              // ~1.7 MB — core astronomical computation
        "AstroCoreLocations",     // adds about +2 MB on top of AstroCore (~3.7 MB total)
    ]
),
```

If your app already has city/coordinate data, import only the core module:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AstroCore"]  // only ~1.7 MB
),
```

Or in Xcode: **File → Add Package Dependencies…** → paste the URL above.

---

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

### 🔧 Low-level API

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

---

## 🎯 Accuracy

Verified against **JPL Horizons** (DE440/441 ephemeris) at 2000-01-01 12:00 UTC:

| | Body | JPL Horizons | AstroCore | Error |
|-|------|-------------|-----------|-------|
| ☀️ | Sun | 280.3689° | 280.369° | **0.36″** |
| 🌙 | Moon | 223.3238° | 223.324° | **0.73″** |
| ☿ | Mercury | 271.8893° | 271.895° | **20.6″** |
| ♀️ | Venus | 241.5658° | 241.570° | **15.2″** |
| ♂️ | Mars | 327.9633° | 327.967° | **13.3″** |
| ♃ | Jupiter | 25.2531° | 25.252° | **3.9″** |
| ♄ | Saturn | 40.3956° | 40.393° | **9.5″** |

> All bodies within 1 arcminute. Sun and Moon accurate to under 1 arcsecond.

### 🧪 Test Coverage

| Metric | Value |
|--------|-------|
| Test functions | **119** |
| Test suites | **23** |

Validation sources:

- ✅ **JPL Horizons (DE440/441)** — Sub-arcsecond Sun/Moon, sub-arcminute planets
- ✅ **Solstice cross-validation** — 2000 summer & 2024 winter solstice error < 1.5″
- ✅ **8 global city ascendants** — NYC, London, Tokyo, Berlin, Sydney, Mumbai, LA, Helsinki
- ✅ **Edge cases** — Year boundaries (1800/2100), polar latitudes, sign boundaries

---

## 🗂️ API Overview

### AstroCore (Core Computation)

| Type | Description |
|------|-------------|
| `AstroCalculator` | Main entry point — Sun/Moon/planet/ascendant/natal chart computation |
| `CivilMoment` | Civil time (year, month, day, hour, minute, second + IANA timezone) |
| `GeoCoordinate` | Geographic coordinate (latitude/longitude) with extreme latitude validation |
| `CelestialBody` | Celestial body enum (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn) |
| `ZodiacSign` | 12 zodiac signs with name, emoji, start longitude, `contains()` |
| `CelestialPosition` | Body position result (ecliptic longitude/latitude, sign, degree in sign) |
| `AscendantResult` | Ascendant result (ecliptic longitude, sign, sidereal time, obliquity) |
| `NatalPositions` | Batch result (ascendant + body dictionary) |
| `AstroError` | Typed errors (invalid coordinate, unsupported year, extreme latitude, etc.) |

### AstroCoreLocations (Optional City Data)

| Type | Description |
|------|-------------|
| `CityIndex` | Singleton city search engine (search / city(forID:)) |
| `CityRecord` | City record (name, country code, coordinate, timezone) |

---

## 📋 Supported Range

| | Item | Range |
|-|------|-------|
| 📆 | Year range | 1800 — 2100 (301 years) |
| 🪐 | Bodies | Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn |
| 🖥️ | Platforms | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift version | 6.0+ |

---

## 🔬 Algorithm References

| Source | Usage |
|--------|-------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | Julian Day, ΔT, sidereal time, nutation, ascendant formulas |
| **VSOP87D** (Bretagnon & Francou, 1988) | Heliocentric ecliptic spherical coordinates (full series) |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | Lunar longitude/latitude (120-term truncated series) |
| **IAU 1980 Nutation Model** | 63-term nutation in longitude/obliquity |
| **Laskar (1986)** | Mean obliquity 10th-degree polynomial |
| **Espenak & Meeus (2006)** | ΔT piecewise polynomials (1800–2100) |
| **JPL Horizons (DE440/441)** | Validation dataset |

---

## 📄 License

[MIT License](LICENSE) © 2026 [Babywbx](https://github.com/babywbx)
