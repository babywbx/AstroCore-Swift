import Foundation

// VSOP87D evaluation engine
// Computes heliocentric ecliptic spherical coordinates (equinox of date)
enum VSOP87D {
    typealias Series = [[(Double, Double, Double)]]
    typealias SeriesBundle = (l: Series, b: Series, r: Series)

    struct SphericalPosition: Sendable {
        let longitude: Double // radians
        let latitude: Double  // radians
        let radius: Double    // AU
    }

    /// Evaluate a VSOP87D series for one coordinate.
    /// terms: array of series [X0, X1, X2, ...] where Xi = [(A, B, C), ...]
    /// tau: Julian millennia from J2000.0 in TT
    /// Returns: the coordinate value (radians for L/B, AU for R)
    @inline(__always)
    static func evaluate(series: [[(Double, Double, Double)]], tau: Double) -> Double {
        var result = 0.0
        for s in series.reversed() {
            var sum = 0.0
            for term in s {
                sum += term.0 * Foundation.cos(term.1 + term.2 * tau)
            }
            result = result * tau + sum
        }
        return result
    }

    private static let earthLongitudeSeries: Series = [
        Earth.L0, Earth.L1, Earth.L2, Earth.L3, Earth.L4, Earth.L5
    ]
    private static let earthLatitudeSeries: Series = [Earth.B0, Earth.B1]
    private static let earthRadiusSeries: Series = [
        Earth.R0, Earth.R1, Earth.R2, Earth.R3, Earth.R4
    ]

    private static let mercurySeries: SeriesBundle = (
        l: [Mercury.L0, Mercury.L1, Mercury.L2, Mercury.L3, Mercury.L4, Mercury.L5],
        b: [Mercury.B0, Mercury.B1, Mercury.B2, Mercury.B3, Mercury.B4],
        r: [Mercury.R0, Mercury.R1, Mercury.R2, Mercury.R3]
    )
    private static let venusSeries: SeriesBundle = (
        l: [Venus.L0, Venus.L1, Venus.L2, Venus.L3, Venus.L4, Venus.L5],
        b: [Venus.B0, Venus.B1, Venus.B2, Venus.B3, Venus.B4],
        r: [Venus.R0, Venus.R1, Venus.R2, Venus.R3, Venus.R4]
    )
    private static let marsSeries: SeriesBundle = (
        l: [Mars.L0, Mars.L1, Mars.L2, Mars.L3, Mars.L4, Mars.L5],
        b: [Mars.B0, Mars.B1, Mars.B2, Mars.B3, Mars.B4, Mars.B5],
        r: [Mars.R0, Mars.R1, Mars.R2, Mars.R3, Mars.R4]
    )
    private static let jupiterSeries: SeriesBundle = (
        l: [Jupiter.L0, Jupiter.L1, Jupiter.L2, Jupiter.L3, Jupiter.L4, Jupiter.L5],
        b: [Jupiter.B0, Jupiter.B1, Jupiter.B2, Jupiter.B3, Jupiter.B4, Jupiter.B5],
        r: [Jupiter.R0, Jupiter.R1, Jupiter.R2, Jupiter.R3, Jupiter.R4, Jupiter.R5]
    )
    private static let saturnSeries: SeriesBundle = (
        l: [Saturn.L0, Saturn.L1, Saturn.L2, Saturn.L3, Saturn.L4, Saturn.L5],
        b: [Saturn.B0, Saturn.B1, Saturn.B2, Saturn.B3, Saturn.B4, Saturn.B5],
        r: [Saturn.R0, Saturn.R1, Saturn.R2, Saturn.R3, Saturn.R4, Saturn.R5]
    )

    /// Compute heliocentric position for Earth.
    @inline(__always)
    static func earthPosition(tau: Double) -> SphericalPosition {
        let l = evaluate(series: earthLongitudeSeries, tau: tau)
        let b = evaluate(series: earthLatitudeSeries, tau: tau)
        let r = evaluate(series: earthRadiusSeries, tau: tau)
        return SphericalPosition(longitude: l, latitude: b, radius: r)
    }

    /// Get heliocentric position series for a planet.
    static func planetSeries(_ body: CelestialBody) -> SeriesBundle {
        switch body {
        case .mercury:
            return mercurySeries
        case .venus:
            return venusSeries
        case .mars:
            return marsSeries
        case .jupiter:
            return jupiterSeries
        case .saturn:
            return saturnSeries
        default:
            fatalError("VSOP87D not available for \(body)")
        }
    }

    /// Compute heliocentric position for any supported planet.
    @inline(__always)
    static func planetPosition(_ series: SeriesBundle, tau: Double) -> SphericalPosition {
        let l = evaluate(series: series.l, tau: tau)
        let b = evaluate(series: series.b, tau: tau)
        let r = evaluate(series: series.r, tau: tau)
        return SphericalPosition(longitude: l, latitude: b, radius: r)
    }

    /// Compute heliocentric position for any supported planet.
    @inline(__always)
    static func planetPosition(_ body: CelestialBody, tau: Double) -> SphericalPosition {
        planetPosition(planetSeries(body), tau: tau)
    }
}
