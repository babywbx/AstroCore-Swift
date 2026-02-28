import Foundation

// Maps ecliptic longitude to zodiac sign
enum ZodiacMapper {
    /// Map ecliptic longitude [0, 360) to a zodiac sign.
    static func sign(forLongitude longitude: Double) -> ZodiacSign {
        precondition(longitude.isFinite, "ZodiacMapper received non-finite longitude")
        let normalized = AngleMath.normalized(degrees: longitude)
        let index = Int(normalized / 30.0) % 12
        return ZodiacSign(rawValue: index)!
    }

    /// Compute degree within the sign (0–30).
    static func degreeInSign(longitude: Double) -> Double {
        let normalized = AngleMath.normalized(degrees: longitude)
        return normalized.truncatingRemainder(dividingBy: 30.0)
    }

    /// True if the longitude is within 0.5° of a 30° boundary.
    static func isBoundaryCase(longitude: Double) -> Bool {
        guard longitude.isFinite else { return false }
        let degInSign = degreeInSign(longitude: longitude)
        return degInSign <= 0.5 || degInSign >= 29.5
    }
}
