import AstroCore
import Foundation

/// Topocentric (Polich-Page, 1961) houses: a closed-form approximation to
/// Placidus. Each intermediate cusp reuses the MC-style projection, but the
/// observer's tan(φ) is scaled by a per-cusp fraction so that the trisection
/// matches Placidus to under 1° at mid latitudes without iteration.
///
/// For cusp n with α_n = ARMC + 30°·(n − 10):
///     cusp 11 / cusp 3: factor = tan(φ)/3
///     cusp 12 / cusp 2: factor = 2·tan(φ)/3
/// and
///     λ_n = atan2(
///               sin(α_n),
///               cos(ε)·cos(α_n) − factor·sin(ε)
///           )
///
/// Cusps 5, 6, 8, 9 are 180° opposites; 1/4/7/10 are the usual angles.
enum TopocentricHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let mc = context.angles.midheaven
        let asc = context.angles.ascendant

        let tanPhi = TrigDeg.tan(phi)
        let sinEps = TrigDeg.sin(epsilon)
        let cosEps = TrigDeg.cos(epsilon)

        func cuspAt(n: Int, factor: Double) -> Double {
            let alpha = ramc + 30.0 * Double(n - 10)
            let numerator = TrigDeg.sin(alpha)
            let denominator = cosEps * TrigDeg.cos(alpha) - factor * sinEps
            return TrigDeg.atan2(numerator, denominator)
        }

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0) // 4
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0) // 7
        cusps[9] = mc // 10

        cusps[10] = cuspAt(n: 11, factor: tanPhi / 3.0) // 11
        cusps[11] = cuspAt(n: 12, factor: 2.0 * tanPhi / 3.0) // 12
        cusps[1] = cuspAt(n: 2, factor: 2.0 * tanPhi / 3.0) // 2
        cusps[2] = cuspAt(n: 3, factor: tanPhi / 3.0) // 3

        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0) // 5
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0) // 6
        cusps[7] = AngleMath.normalized(degrees: cusps[1] + 180.0) // 8
        cusps[8] = AngleMath.normalized(degrees: cusps[2] + 180.0) // 9

        return cusps
    }
}
