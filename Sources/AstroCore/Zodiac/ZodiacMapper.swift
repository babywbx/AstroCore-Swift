import Foundation

// Maps ecliptic longitude to zodiac sign
enum ZodiacMapper {
    typealias Details = (
        sign: ZodiacSign,
        degreeInSign: Double,
        isBoundaryCase: Bool
    )

    /// Map ecliptic longitude [0, 360) to a zodiac sign.
    static func sign(forLongitude longitude: Double) -> ZodiacSign {
        let normalized = AngleMath.normalized(degrees: longitude)
        return details(forNormalizedLongitude: normalized).sign
    }

    /// Compute degree within the sign (0–30).
    static func degreeInSign(longitude: Double) -> Double {
        let normalized = AngleMath.normalized(degrees: longitude)
        return details(forNormalizedLongitude: normalized).degreeInSign
    }

    /// True if the longitude is within 0.5° of a 30° boundary.
    static func isBoundaryCase(longitude: Double) -> Bool {
        guard longitude.isFinite else { return false }
        let normalized = AngleMath.normalized(degrees: longitude)
        return details(forNormalizedLongitude: normalized).isBoundaryCase
    }

    /// Compute all zodiac-derived metadata from a normalized longitude [0, 360).
    static func details(forNormalizedLongitude longitude: Double) -> Details {
        precondition(longitude.isFinite, "ZodiacMapper received non-finite longitude")
        let index = Int(longitude / 30.0) % 12
        let degreeInSign = longitude - Double(index) * 30.0
        return (
            sign: ZodiacSign(rawValue: index)!,
            degreeInSign: degreeInSign,
            isBoundaryCase: degreeInSign <= 0.5 || degreeInSign >= 29.5
        )
    }
}
