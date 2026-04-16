import Foundation

// Equal-division house systems. All three are the same idea with different
// anchor points:
//   * Equal (ASC):   cusp 1 = ASC, each cusp = previous + 30°
//   * Equal (MC):    cusp 10 = MC, cusp 1 = MC + 90°, etc.
//   * Vehlow Equal:  cusp 1 = ASC − 15° (ASC sits mid-house instead of on cusp)
enum EqualHouses {
    static func cuspsFromAscendant(context: HouseEngine.Context) -> [Double] {
        let start = context.angles.ascendant
        return (0..<12).map { n in start + Double(n) * 30.0 }
    }

    static func cuspsFromMidheaven(context: HouseEngine.Context) -> [Double] {
        // cusp 10 = MC, so cusp 1 = MC + 3 × 30° = MC + 90°.
        let cusp1 = context.angles.midheaven + 90.0
        return (0..<12).map { n in cusp1 + Double(n) * 30.0 }
    }

    static func cuspsVehlow(context: HouseEngine.Context) -> [Double] {
        let start = context.angles.ascendant - 15.0
        return (0..<12).map { n in start + Double(n) * 30.0 }
    }
}
