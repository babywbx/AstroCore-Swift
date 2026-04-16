import Foundation

// Regiomontanus houses: 12 equal divisions of the celestial equator measured
// from the meridian (ARMC). Each house-circle passes through the north and
// south horizon points, so all twelve meet there — a great-circle "pencil"
// rotated about the horizon N-S axis.
//
// Derivation: the house plane through the N/S horizon poles and the equator
// at RA = ARMC + M_n has the constraint:
//     sin(α − α₀) = tan(δ) · tan(φ) · sin(M_n)
// Substituting the ecliptic point (λ, β = 0) into it collapses to the
// explicit cusp formula below.
//
// For cusp n (n = 1…12):
//     M_n = 30° × (n − 10)   (so M = 0 at MC, 90° at ASC, 180° at IC, …)
//     λ_n = atan2(
//               sin(ARMC + M_n),
//               cos(ε)·cos(ARMC + M_n) − tan(φ)·sin(M_n)·sin(ε)
//           )
enum RegiomontanusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let tanPhi = TrigDeg.tan(phi)
        let sinEps = TrigDeg.sin(epsilon)
        let cosEps = TrigDeg.cos(epsilon)

        return (1...12).map { n in
            let m = 30.0 * Double(n - 10)
            let alpha = ramc + m
            let sinAlpha = TrigDeg.sin(alpha)
            let cosAlpha = TrigDeg.cos(alpha)
            let sinM = TrigDeg.sin(m)

            let numerator = sinAlpha
            let denominator = cosEps * cosAlpha - tanPhi * sinM * sinEps
            return TrigDeg.atan2(numerator, denominator)
        }
    }
}
