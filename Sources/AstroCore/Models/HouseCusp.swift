/// A single house cusp. Cusp n is the starting boundary of house n.
public struct HouseCusp: Sendable, Hashable, Codable {
    /// House number. 1...12 for 12-house systems.
    public let number: Int
    /// Ecliptic longitude in [0, 360).
    public let eclipticLongitude: Double
    public let sign: ZodiacSign
    /// Degree within the sign, 0 ≤ degree < 30.
    public let degreeInSign: Double
}
