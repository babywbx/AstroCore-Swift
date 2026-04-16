import Foundation

// Campanus houses: 12 equal divisions of the prime vertical (the great circle
// through east, zenith, west, nadir). House-circles share the same N-S horizon
// poles as Regiomontanus — only the reference great circle differs.
//
// Parameterize the prime vertical by M, measured from the east horizon point
// toward the zenith:
//     M = 0   → East (cusp 1 = ASC)
//     M = 90° → Zenith (cusp 10 = MC, by great-circle coincidence through
//                       the meridian)
//     M = 180°→ West (cusp 7 = DSC)
//     M = 270°→ Nadir (cusp 4 = IC)
//
// Chart numbering runs counterclockwise while M advances clockwise along the
// prime vertical, so the cusp-to-M map is M_n = −(n − 1) × 30°.
//
// The derivation (plane through N/S horizon poles + the prime-vertical point
// at angle M) yields:
//     λ_n = atan2(
//               sin(M)·sin(ARMC) + cos(M)·cos(φ)·cos(ARMC),
//               cos(ε)·[sin(M)·cos(ARMC) − cos(M)·cos(φ)·sin(ARMC)]
//                   − sin(φ)·cos(M)·sin(ε)
//           )
enum CampanusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let sinRamc = TrigDeg.sin(ramc)
        let cosRamc = TrigDeg.cos(ramc)
        let sinEps = TrigDeg.sin(epsilon)
        let cosEps = TrigDeg.cos(epsilon)
        let sinPhi = TrigDeg.sin(phi)
        let cosPhi = TrigDeg.cos(phi)

        return (1...12).map { n in
            let m = -Double(n - 1) * 30.0
            let sinM = TrigDeg.sin(m)
            let cosM = TrigDeg.cos(m)

            let numerator = sinM * sinRamc + cosM * cosPhi * cosRamc
            let denominator = cosEps * (sinM * cosRamc - cosM * cosPhi * sinRamc)
                - sinPhi * cosM * sinEps
            return TrigDeg.atan2(numerator, denominator)
        }
    }
}
