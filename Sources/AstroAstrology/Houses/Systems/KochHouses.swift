import AstroCore
import Foundation

// Koch (Geburts-Orts-Häuser, "birthplace houses"): express the cusps as
// Asc1 evaluations at four rectascensions derived from the MC's geometry.
//
// With th = ARMC, fi = geographic latitude, ε = obliquity and MC = λ_MC:
//     sina = sin(MC) · sin(ε) / cos(fi)
//     c    = atan(tan(fi) / cos(asin(sina)))
//     ad3  = asin(sin(c) · sina) / 3
//
// Then:
//     cusp 11 = Asc1(th + 30°  − 2·ad3, fi)
//     cusp 12 = Asc1(th + 60°  − ad3,   fi)
//     cusp  2 = Asc1(th + 120° + ad3,   fi)
//     cusp  3 = Asc1(th + 150° + 2·ad3, fi)
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

        let sinA = TrigDeg.sin(mc) * TrigDeg.sin(epsilon) / TrigDeg.cos(phi)
        let clampedSinA = max(-1.0, min(1.0, sinA))
        let cosA = (1.0 - clampedSinA * clampedSinA).squareRoot()
        let c = TrigDeg.atan2(TrigDeg.tan(phi), cosA)
        let ad3 = TrigDeg.asin(TrigDeg.sin(c) * clampedSinA) / 3.0

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0) // 4 (IC)
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0) // 7 (DSC)
        cusps[9] = mc // 10

        cusps[10] = asc1(argumentDegrees: ramc + 30.0 - 2.0 * ad3, phi: phi, epsilon: epsilon) // 11
        cusps[11] = asc1(argumentDegrees: ramc + 60.0 - ad3, phi: phi, epsilon: epsilon) // 12
        cusps[1] = asc1(argumentDegrees: ramc + 120.0 + ad3, phi: phi, epsilon: epsilon) // 2
        cusps[2] = asc1(argumentDegrees: ramc + 150.0 + 2.0 * ad3, phi: phi, epsilon: epsilon) // 3

        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0) // 5 = 11+180
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0) // 6 = 12+180
        cusps[7] = AngleMath.normalized(degrees: cusps[1] + 180.0) // 8 = 2+180
        cusps[8] = AngleMath.normalized(degrees: cusps[2] + 180.0) // 9 = 3+180

        return cusps
    }

    private static func asc1(
        argumentDegrees: Double,
        phi: Double,
        epsilon: Double
    ) -> Double {
        Axis.ascendantLongitude(
            lastDegrees: AngleMath.normalized(degrees: argumentDegrees - 90.0),
            trueObliquityDegrees: epsilon,
            latitudeDegrees: phi
        )
    }
}
