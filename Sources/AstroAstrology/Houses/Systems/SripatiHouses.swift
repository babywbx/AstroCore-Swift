import AstroCore
import Foundation

/// Sripati houses: a Porphyry-derived system used in traditional Vedic
/// astrology. Each Sripati cusp sits at the midpoint between consecutive
/// Porphyry cusps; the original Porphyry cusps become "bhava madhya" (house
/// centers) in the Vedic reading.
enum SripatiHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let porphyry = PorphyryHouses.porphyryCusps(angles: context.angles)
        return (0..<12).map { i in
            let start = AngleMath.normalized(degrees: porphyry[(i + 11) % 12])
            let end = AngleMath.normalized(degrees: porphyry[i])
            let delta = AngleMath.normalized(degrees: end - start)
            return AngleMath.normalized(degrees: start + delta / 2.0)
        }
    }
}
