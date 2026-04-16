import Foundation

// Placidus houses: each intermediate cusp is the ecliptic point that has
// completed a specific fraction of its own semi-diurnal arc. The system has
// no closed-form solution — both the cusp's right ascension α and its
// semi-diurnal arc H depend on the unknown longitude λ, so we iterate.
//
// For cusp n the hour-angle condition is α(λ) = ARMC + f · H(λ), giving:
//     n = 11: f = +1/3  (α is 1/3 of SA east-side past MC)
//     n = 12: f = +2/3
//     n = 8:  f = −2/3  (west-side past MC toward DSC)
//     n = 9:  f = −1/3
// Cusps 2, 3, 5, 6 are simply the 180° opposites of 8, 9, 11, 12.
//
// Iteration (Porphyry cusp as seed, 3–5 iterations typical):
//     δ_k = arcsin(sin(λ_k) · sin(ε))
//     H_k = arccos(−tan(φ) · tan(δ_k))           [polar check: |tan(φ)·tan(δ)| < 1]
//     α_k = ARMC + f · H_k
//     λ_{k+1} = atan2(sin(α_k), cos(α_k) · cos(ε))
//
// Precondition: dispatcher has routed polar latitudes (|φ| > ~66°) away.
enum PlacidusHouses {
    private static let maxIterations = 60
    private static let convergenceDegrees = 1e-10

    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let mc = context.angles.midheaven
        let asc = context.angles.ascendant
        let porphyry = PorphyryHouses.porphyryCusps(angles: context.angles)

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc                                              // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0)        // 4 (IC)
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0)       // 7 (DSC)
        cusps[9] = mc                                               // 10

        // East-of-meridian, above horizon: cusps 11, 12
        cusps[10] = solve(
            fraction: 1.0 / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon,
            initial: porphyry[10]
        )                                                           // 11
        cusps[11] = solve(
            fraction: 2.0 / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon,
            initial: porphyry[11]
        )                                                           // 12
        // West-of-meridian, above horizon: cusps 8, 9
        cusps[7] = solve(
            fraction: -2.0 / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon,
            initial: porphyry[7]
        )                                                           // 8
        cusps[8] = solve(
            fraction: -1.0 / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon,
            initial: porphyry[8]
        )                                                           // 9

        // Below-horizon cusps are opposites.
        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0) // 5
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0) // 6
        cusps[1] = AngleMath.normalized(degrees: cusps[7] + 180.0)  // 2
        cusps[2] = AngleMath.normalized(degrees: cusps[8] + 180.0)  // 3

        return cusps
    }

    /// Iteratively solve α(λ) = ARMC + f · H(λ) for λ.
    private static func solve(
        fraction f: Double,
        ramc: Double,
        phi: Double,
        epsilon: Double,
        initial: Double
    ) -> Double {
        var lambda = initial
        let tanPhi = TrigDeg.tan(phi)
        let sinEps = TrigDeg.sin(epsilon)
        let cosEps = TrigDeg.cos(epsilon)

        for _ in 0..<maxIterations {
            let sinDelta = TrigDeg.sin(lambda) * sinEps
            let cos2Delta = 1.0 - sinDelta * sinDelta
            guard cos2Delta > 1e-20 else { break }
            let cosDelta = cos2Delta.squareRoot()
            let tanDelta = sinDelta / cosDelta

            let polarFactor = tanPhi * tanDelta
            // Clamp defensively: the dispatcher's polar pre-check is by latitude
            // and won't catch borderline MC declinations near the arctic circle.
            let clamped = max(-1.0, min(1.0, -polarFactor))
            let H = TrigDeg.acos(clamped)
            let alpha = ramc + f * H

            let newLambda = AngleMath.normalized(
                degrees: TrigDeg.atan2(TrigDeg.sin(alpha), TrigDeg.cos(alpha) * cosEps)
            )

            // Shortest angular distance for the convergence check.
            var diff = newLambda - lambda
            if diff > 180.0 { diff -= 360.0 }
            if diff < -180.0 { diff += 360.0 }
            if abs(diff) < convergenceDegrees {
                return newLambda
            }
            lambda = newLambda
        }
        return lambda
    }
}
