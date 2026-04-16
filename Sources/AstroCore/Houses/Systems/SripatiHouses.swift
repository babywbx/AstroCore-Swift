import Foundation

// Sripati houses: a Porphyry-derived system used in traditional Vedic
// astrology. Each Sripati cusp sits at the midpoint between consecutive
// Porphyry cusps; the original Porphyry cusps become "bhava madhya" (house
// centers) in the Vedic reading.
enum SripatiHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let porphyry = PorphyryHouses.porphyryCusps(angles: context.angles)
        return (0..<12).map { i in
            let start = porphyry[i]
            let end = porphyry[(i + 1) % 12]
            let delta = AngleMath.normalized(degrees: end - start)
            return start + delta / 2.0
        }
    }
}
