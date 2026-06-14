import AstroCore
import Foundation

// Alcabitius houses: Munkasey's semiarc construction.
// It computes the Ascendant's declination, divides its semi-diurnal and
// semi-nocturnal arcs into thirds, then projects the resulting rectascensions
// to the ecliptic using Asc1 with pole height 0.
//
// With th = ARMC, φ = latitude, ε = obliquity and ASC = λ_ASC:
//     δ_ASC = asin(sin(ASC) · sin(ε))
//     sda   = acos(−tan(φ) · tan(δ_ASC))
//     sna   = 180° − sda
//
// Then:
//     cusp 11 = Asc1(th + sda / 3,         0)
//     cusp 12 = Asc1(th + 2·sda / 3,       0)
//     cusp  2 = Asc1(th + 180° − 2·sna/3,  0)
//     cusp  3 = Asc1(th + 180° − sna/3,    0)
//
// Cusps 5, 6, 8, 9 are the 180° opposites. Angles sit on 1/4/7/10 as usual.
//
// Precondition: the dispatcher's polar pre-check must route |φ| > ~66° away,
// where SA_ASC becomes undefined.
enum AlcabitiusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let mc = context.angles.midheaven
        let asc = context.angles.ascendant

        let declAsc = TrigDeg.asin(TrigDeg.sin(asc) * TrigDeg.sin(epsilon))
        let r = max(-1.0, min(1.0, -TrigDeg.tan(phi) * TrigDeg.tan(declAsc)))
        let sda = TrigDeg.acos(r)
        let sna = 180.0 - sda
        let sd3 = sda / 3.0
        let sn3 = sna / 3.0

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0) // 4
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0) // 7
        cusps[9] = mc // 10

        cusps[10] = asc1(argumentDegrees: ramc + sd3, poleHeight: 0.0, epsilon: epsilon) // 11
        cusps[11] = asc1(argumentDegrees: ramc + 2.0 * sd3, poleHeight: 0.0, epsilon: epsilon) // 12
        cusps[1] = asc1(argumentDegrees: ramc + 180.0 - 2.0 * sn3, poleHeight: 0.0, epsilon: epsilon) // 2
        cusps[2] = asc1(argumentDegrees: ramc + 180.0 - sn3, poleHeight: 0.0, epsilon: epsilon) // 3

        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0) // 5
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0) // 6
        cusps[7] = AngleMath.normalized(degrees: cusps[1] + 180.0) // 8
        cusps[8] = AngleMath.normalized(degrees: cusps[2] + 180.0) // 9

        return cusps
    }

    private static func asc1(
        argumentDegrees: Double,
        poleHeight: Double,
        epsilon: Double
    ) -> Double {
        Axis.ascendantLongitude(
            lastDegrees: AngleMath.normalized(degrees: argumentDegrees - 90.0),
            trueObliquityDegrees: epsilon,
            latitudeDegrees: poleHeight
        )
    }
}
