import AstroCore
import Foundation

/// Morinus houses: pure 12-fold division of the celestial equator measured
/// from ARMC, each equator point transformed into ecliptic coordinates.
///
/// The numbering mirrors the meridian layout:
///     cusp 11 ← α = ARMC + 30°
///     cusp 12 ← α = ARMC + 60°
///     cusp  1 ← α = ARMC + 90°
///     ...
///     cusp 10 ← α = ARMC + 360° (= ARMC)
///
/// A point on the celestial equator has equatorial coordinates (α, δ = 0).
/// Transforming that point to the ecliptic yields:
///     λ = atan2(sin(α) · cos(ε), cos(α))
///
/// Morinus therefore does NOT force cusp 10 to equal the MC, and cusp 1 is not
/// the Ascendant either. Latitude never enters the formula, so Morinus is
/// defined at every latitude including the poles.
enum MorinusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let cosEps = TrigDeg.cos(context.obliquityDegrees)

        return (1...12).map { n in
            let alpha = AngleMath.normalized(
                degrees: ramc + 30.0 * Double(n + 2)
            )
            return TrigDeg.atan2(TrigDeg.sin(alpha) * cosEps, TrigDeg.cos(alpha))
        }
    }
}
