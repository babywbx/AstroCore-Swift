import AstroCore
import Foundation

/// Meridian (axial rotation / Zariel) houses: take ecliptic points whose right ascensions are
/// ARMC + n·30° and use those points directly as cusps.
///
/// The numbering places house 10, not house 1, on the MC. The sequence is:
///     cusp 11 ← α = ARMC + 30°
///     cusp 12 ← α = ARMC + 60°
///     cusp  1 ← α = ARMC + 90°
///     ...
///     cusp 10 ← α = ARMC + 360° (= ARMC)
///
/// Each cusp solves tan(λ) = tan(α) / cos(ε), i.e.:
///     λ = atan2(sin(α), cos(α) · cos(ε))
///
/// Latitude never enters the formula, so the system is defined at every pole.
enum MeridianHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let cosEps = TrigDeg.cos(context.obliquityDegrees)

        return (1...12).map { n in
            let alpha = AngleMath.normalized(
                degrees: ramc + 30.0 * Double(n + 2)
            )
            return TrigDeg.atan2(TrigDeg.sin(alpha), TrigDeg.cos(alpha) * cosEps)
        }
    }
}
