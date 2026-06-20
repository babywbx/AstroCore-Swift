import Accelerate
import Foundation

/// VSOP87D evaluation engine
/// Computes heliocentric ecliptic spherical coordinates (equinox of date)
enum VSOP87D {
    struct SphericalPosition: Sendable {
        let longitude: Double // radians
        let latitude: Double // radians
        let radius: Double // AU
    }

    /// One power-level of a series, stored column-major as [A…, B…, C…] for vectorized evaluation.
    struct FlatLevel: Sendable {
        let columns: [Double]
        @inline(__always) var count: Int { columns.count / 3 }
    }

    typealias FlatSeries = [FlatLevel]
    typealias SeriesBundle = (l: FlatSeries, b: FlatSeries, r: FlatSeries)

    @inline(__always)
    private static func levels(_ data: [[Double]]) -> FlatSeries {
        data.map { FlatLevel(columns: $0) }
    }

    /// Evaluate a VSOP87D series for one coordinate.
    /// Each power-level sum Σ Aᵢ·cos(Bᵢ + Cᵢ·tau) is computed with Accelerate
    /// (vDSP/vForce) at full double precision; the Horner fold over tau is unchanged.
    @inline(__always)
    static func evaluate(_ series: FlatSeries, tau: Double) -> Double {
        var capacity = 1
        for level in series {
            capacity = Swift.max(capacity, level.count)
        }

        var result = 0.0
        withUnsafeTemporaryAllocation(of: Double.self, capacity: capacity) { scratch in
            let cosArg = scratch.baseAddress!
            for level in series.reversed() {
                let n = level.count
                var sum = 0.0
                if n > 0 {
                    level.columns.withUnsafeBufferPointer { col in
                        let a = col.baseAddress!
                        let b = a + n
                        let c = b + n
                        var tauScalar = tau
                        // cosArg = c·tau + b
                        vDSP_vsmaD(c, 1, &tauScalar, b, 1, cosArg, 1, vDSP_Length(n))
                        var count = Int32(n)
                        vvcos(cosArg, cosArg, &count)
                        vDSP_dotprD(a, 1, cosArg, 1, &sum, vDSP_Length(n))
                    }
                }
                result = result * tau + sum
            }
        }
        return result
    }

    private static let earthLongitudeSeries: FlatSeries = levels([
        Earth.L0, Earth.L1, Earth.L2, Earth.L3, Earth.L4, Earth.L5
    ])
    private static let earthLatitudeSeries: FlatSeries = levels([Earth.B0, Earth.B1])
    private static let earthRadiusSeries: FlatSeries = levels([
        Earth.R0, Earth.R1, Earth.R2, Earth.R3, Earth.R4
    ])

    private static let mercurySeries: SeriesBundle = (
        l: levels([Mercury.L0, Mercury.L1, Mercury.L2, Mercury.L3, Mercury.L4, Mercury.L5]),
        b: levels([Mercury.B0, Mercury.B1, Mercury.B2, Mercury.B3, Mercury.B4]),
        r: levels([Mercury.R0, Mercury.R1, Mercury.R2, Mercury.R3])
    )
    private static let venusSeries: SeriesBundle = (
        l: levels([Venus.L0, Venus.L1, Venus.L2, Venus.L3, Venus.L4, Venus.L5]),
        b: levels([Venus.B0, Venus.B1, Venus.B2, Venus.B3, Venus.B4]),
        r: levels([Venus.R0, Venus.R1, Venus.R2, Venus.R3, Venus.R4])
    )
    private static let marsSeries: SeriesBundle = (
        l: levels([Mars.L0, Mars.L1, Mars.L2, Mars.L3, Mars.L4, Mars.L5]),
        b: levels([Mars.B0, Mars.B1, Mars.B2, Mars.B3, Mars.B4, Mars.B5]),
        r: levels([Mars.R0, Mars.R1, Mars.R2, Mars.R3, Mars.R4])
    )
    private static let jupiterSeries: SeriesBundle = (
        l: levels([Jupiter.L0, Jupiter.L1, Jupiter.L2, Jupiter.L3, Jupiter.L4, Jupiter.L5]),
        b: levels([Jupiter.B0, Jupiter.B1, Jupiter.B2, Jupiter.B3, Jupiter.B4, Jupiter.B5]),
        r: levels([Jupiter.R0, Jupiter.R1, Jupiter.R2, Jupiter.R3, Jupiter.R4, Jupiter.R5])
    )
    private static let saturnSeries: SeriesBundle = (
        l: levels([Saturn.L0, Saturn.L1, Saturn.L2, Saturn.L3, Saturn.L4, Saturn.L5]),
        b: levels([Saturn.B0, Saturn.B1, Saturn.B2, Saturn.B3, Saturn.B4, Saturn.B5]),
        r: levels([Saturn.R0, Saturn.R1, Saturn.R2, Saturn.R3, Saturn.R4, Saturn.R5])
    )
    private static let uranusSeries: SeriesBundle = (
        l: levels([Uranus.L0, Uranus.L1, Uranus.L2, Uranus.L3, Uranus.L4, Uranus.L5]),
        b: levels([Uranus.B0, Uranus.B1, Uranus.B2, Uranus.B3, Uranus.B4]),
        r: levels([Uranus.R0, Uranus.R1, Uranus.R2, Uranus.R3, Uranus.R4])
    )
    private static let neptuneSeries: SeriesBundle = (
        l: levels([Neptune.L0, Neptune.L1, Neptune.L2, Neptune.L3, Neptune.L4, Neptune.L5]),
        b: levels([Neptune.B0, Neptune.B1, Neptune.B2, Neptune.B3, Neptune.B4, Neptune.B5]),
        r: levels([Neptune.R0, Neptune.R1, Neptune.R2, Neptune.R3, Neptune.R4])
    )

    /// Compute heliocentric position for Earth.
    @inline(__always)
    static func earthPosition(tau: Double) -> SphericalPosition {
        let l = evaluate(earthLongitudeSeries, tau: tau)
        let b = evaluate(earthLatitudeSeries, tau: tau)
        let r = evaluate(earthRadiusSeries, tau: tau)
        return SphericalPosition(longitude: l, latitude: b, radius: r)
    }

    /// Get heliocentric position series for a planet.
    /// Sun and Moon use dedicated engines (SolarPosition, ELP2000).
    static func planetSeries(_ body: CelestialBody) -> SeriesBundle {
        switch body {
        case .mercury: mercurySeries
        case .venus: venusSeries
        case .mars: marsSeries
        case .jupiter: jupiterSeries
        case .saturn: saturnSeries
        case .uranus: uranusSeries
        case .neptune: neptuneSeries
        case .sun, .moon, .pluto, .meanNode, .trueNode, .lilith, .trueLilith:
            fatalError("Use a dedicated engine for \(body)")
        }
    }

    /// Compute heliocentric position for any supported planet.
    @inline(__always)
    static func planetPosition(_ series: SeriesBundle, tau: Double) -> SphericalPosition {
        let l = evaluate(series.l, tau: tau)
        let b = evaluate(series.b, tau: tau)
        let r = evaluate(series.r, tau: tau)
        return SphericalPosition(longitude: l, latitude: b, radius: r)
    }

    /// Compute heliocentric position for any supported planet.
    @inline(__always)
    static func planetPosition(_ body: CelestialBody, tau: Double) -> SphericalPosition {
        planetPosition(planetSeries(body), tau: tau)
    }
}
