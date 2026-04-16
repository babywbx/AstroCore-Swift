import Foundation

// Koch (Geburts-Orts-Häuser, "birthplace houses"): trisect the MC's
// semi-diurnal arc at the observer's geographic latitude, then compute the
// Ascendant for each offset sidereal time.
//
// Let H_MC = arccos(−tan(φ)·tan(δ_MC)) be the MC's semi-diurnal arc.
//   cusp 11 = ASC formula evaluated at ARMC − 2·H_MC/3
//   cusp 12 = ASC formula evaluated at ARMC − H_MC/3
//   cusp 2  = ASC formula evaluated at ARMC + H_IC/3
//   cusp 3  = ASC formula evaluated at ARMC + 2·H_IC/3
// where H_IC = 180° − H_MC is the IC's semi-diurnal arc (same latitude).
//
// The remaining cusps are angles (1, 4, 7, 10) or 180° opposites of the four
// computed cusps (5 = 11+180°, 6 = 12+180°, 8 = 2+180°, 9 = 3+180°).
//
// Precondition: the dispatcher's polar-circle pre-check must have routed the
// call away when |φ| > ~66°, where H_MC becomes undefined.
enum KochHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let mc = context.angles.midheaven
        let asc = context.angles.ascendant

        // MC's declination and semi-diurnal arc at this latitude.
        let sinDelta = TrigDeg.sin(epsilon) * TrigDeg.sin(mc)
        let cosDelta = (1.0 - sinDelta * sinDelta).squareRoot()
        let tanDelta = sinDelta / cosDelta
        let polarFactor = TrigDeg.tan(phi) * tanDelta
        // H is clamped in case the pre-check left a numerically borderline value;
        // the dispatcher already routed polar latitudes to a fallback system.
        let clamped = max(-1.0, min(1.0, -polarFactor))
        let hMC = TrigDeg.acos(clamped)
        let hIC = 180.0 - hMC

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc                                                  // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0)            // 4 (IC)
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0)           // 7 (DSC)
        cusps[9] = mc                                                   // 10

        cusps[10] = ascendantAt(
            ramcOffset: -2.0 * hMC / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon
        )                                                               // 11
        cusps[11] = ascendantAt(
            ramcOffset: -hMC / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon
        )                                                               // 12
        cusps[1] = ascendantAt(
            ramcOffset: hIC / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon
        )                                                               // 2
        cusps[2] = ascendantAt(
            ramcOffset: 2.0 * hIC / 3.0,
            ramc: ramc, phi: phi, epsilon: epsilon
        )                                                               // 3

        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0)     // 5 = 11+180
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0)     // 6 = 12+180
        cusps[7] = AngleMath.normalized(degrees: cusps[1] + 180.0)      // 8 = 2+180
        cusps[8] = AngleMath.normalized(degrees: cusps[2] + 180.0)      // 9 = 3+180

        return cusps
    }

    private static func ascendantAt(
        ramcOffset: Double,
        ramc: Double,
        phi: Double,
        epsilon: Double
    ) -> Double {
        AscendantEngine.ascendantLongitude(
            lastDegrees: AngleMath.normalized(degrees: ramc + ramcOffset),
            trueObliquityDegrees: epsilon,
            latitudeDegrees: phi
        )
    }
}
