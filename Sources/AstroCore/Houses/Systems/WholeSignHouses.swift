import Foundation

// Whole Sign houses: the sign containing ASC is the 1st house; each subsequent
// sign is the next house. Cusps land on exact 0° of each sign.
enum WholeSignHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ascSignStart = (context.angles.ascendant / 30.0).rounded(.down) * 30.0
        return (0..<12).map { n in ascSignStart + Double(n) * 30.0 }
    }
}
