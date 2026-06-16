import AstroCore
import Foundation

/// Shared iterative solver for semi-arc based house constructions.
enum SemiArcInterpolation {
    private static let maxIterations = 60
    private static let convergenceDegrees = 1e-10

    struct Context {
        let tanLatitude: Double
        let sinObliquity: Double
        let cosObliquity: Double

        init(latitude: Double, obliquity: Double) {
            tanLatitude = TrigDeg.tan(latitude)
            let obliquityTrig = TrigDeg.sincos(obliquity)
            sinObliquity = obliquityTrig.sin
            cosObliquity = obliquityTrig.cos
        }
    }

    /// Solve α(λ) = ARMC + f · H(λ) for the ecliptic longitude λ.
    static func solve(
        fraction: Double,
        ramc: Double,
        latitude: Double,
        obliquity: Double,
        initial: Double
    ) -> Double {
        solve(
            fraction: fraction,
            ramc: ramc,
            context: Context(latitude: latitude, obliquity: obliquity),
            initial: initial
        )
    }

    /// Solve α(λ) = ARMC + f · H(λ), reusing fixed latitude/obliquity terms.
    static func solve(
        fraction: Double,
        ramc: Double,
        context: Context,
        initial: Double
    ) -> Double {
        var lambda = initial

        for _ in 0..<maxIterations {
            let sinDeclination = TrigDeg.sin(lambda) * context.sinObliquity
            let cosDeclinationSquared = 1.0 - sinDeclination * sinDeclination
            guard cosDeclinationSquared > 1e-20 else { break }

            let tanDeclination = sinDeclination / cosDeclinationSquared.squareRoot()
            let polarFactor = context.tanLatitude * tanDeclination
            let clamped = max(-1.0, min(1.0, -polarFactor))
            let semiArc = TrigDeg.acos(clamped)
            let rightAscension = ramc + fraction * semiArc

            let nextLongitude = AngleMath.normalized(
                degrees: TrigDeg.atan2(
                    TrigDeg.sin(rightAscension),
                    TrigDeg.cos(rightAscension) * context.cosObliquity
                )
            )

            var delta = nextLongitude - lambda
            if delta > 180.0 { delta -= 360.0 }
            if delta < -180.0 { delta += 360.0 }
            if abs(delta) < convergenceDegrees {
                return nextLongitude
            }
            lambda = nextLongitude
        }

        return lambda
    }
}
