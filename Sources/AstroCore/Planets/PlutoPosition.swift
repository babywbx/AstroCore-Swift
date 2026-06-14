import Foundation

/// Pluto heliocentric position fit for the supported 1800-2100 range.
enum PlutoPosition {
    static func heliocentric(tau: Double) -> VSOP87D.SphericalPosition {
        let t = tau * 10.0 // Julian centuries TT
        return VSOP87D.SphericalPosition(
            longitude: AngleMath.toRadians(
                evaluate(PlutoData.longitudePoly, PlutoData.longitudeTerms, t)
            ),
            latitude: AngleMath.toRadians(
                evaluate(PlutoData.latitudePoly, PlutoData.latitudeTerms, t)
            ),
            radius: evaluate(PlutoData.radiusPoly, PlutoData.radiusTerms, t)
        )
    }

    @inline(__always)
    private static func evaluate(
        _ poly: [Double],
        _ terms: [(f: Double, a: Double, b: Double)],
        _ t: Double
    ) -> Double {
        var result = 0.0
        var power = 1.0
        for coefficient in poly {
            result += coefficient * power
            power *= t
        }
        for term in terms {
            let argument = 2.0 * Double.pi * term.f * t
            result += term.a * Foundation.sin(argument) + term.b * Foundation.cos(argument)
        }
        return result
    }
}
