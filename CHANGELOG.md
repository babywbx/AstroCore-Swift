# Changelog

All notable changes to this project are documented here.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0]

A major release that splits the package into focused modules and adds a large
astrology and events feature set on top of the core astronomy engine.

### Added

- **`AstroAstrology` module** — astrology now ships as its own library product.
  The package exposes three products: `AstroCore` (astronomy), `AstroAstrology`
  (signs, houses, charts, aspects), and `AstroCoreLocations` (optional city data).
- **Aspects** — single-pair aspects, full aspect grids, applying/separating and
  exactness, exact-moment solving, cross-chart synastry, and chart-angle aspects
  (`AspectGrid`, `ChartAspectGrid`, `CrossAspectGrid`, `Aspect`, `OrbPolicy`,
  11 `AspectKind` values).
- **Aspect patterns** — multi-body pattern detection (`AspectPattern`,
  `AspectPatternKind`).
- **Rise / set / transit events** — civil-day rise/set, meridian transits, and
  twilight overlays (`RiseSetEvents`, `EventInstant`).
- **Stations & retrograde** — direct/retrograde station solving and retrograde
  intervals (`Station`, `StationKind`).
- **Derived coordinate frames** — equatorial, topocentric horizontal (with
  refraction), and heliocentric outputs.
- **Illumination & equation of time** — phase/illuminated-fraction and equation
  of time.
- **Motion states** — per-body longitude speed and retrograde flags
  (`CelestialState`, `NatalStates`).
- **Extended bodies** — Uranus, Neptune, Pluto, lunar nodes (mean/true), and
  Black Moon Lilith (mean/true), under tiered precision.
- **`ZodiacSign(longitude:)`** — convenience initializer mapping an ecliptic
  longitude to its sign.

### Changed

- **BREAKING — astrology APIs moved modules.** `ascendant`, `houses`,
  `gauquelinSectors`, `natalPositions`, and related sign/house/chart entry points
  now live on `AstrologyCalculator` in the `AstroAstrology` module. Add
  `import AstroAstrology` and call `AstrologyCalculator.*`. `AstroCore` retains
  only the zodiac-free primitives (e.g. `AstroCalculator.ascendantLongitude`).
- **BREAKING — `CelestialPosition` is astronomy-only.** It no longer carries
  `sign`, `degreeInSign`, or `isBoundaryCase`; it gained an optional `distance`
  (geocentric, AU). Derive the sign with `ZodiacSign(longitude:)`.
- All module `version` constants are `3.0.0`, and release verification now gates
  on version consistency.

### Migration from 2.x

```swift
// 2.x
import AstroCore
let asc = try AstroCalculator.ascendant(for: moment, coordinate: coord)
let sign = sun.sign

// 3.0
import AstroCore
import AstroAstrology
let asc = try AstrologyCalculator.ascendant(for: moment, coordinate: coord)
let sign = ZodiacSign(longitude: sun.longitude)
```

## Earlier releases

See the [GitHub Releases](https://github.com/wbx1-Ltd/AstroCore-Swift/releases)
page for 1.x and 2.0.0 history.
