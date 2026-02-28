public struct CelestialPosition: Sendable, Hashable, Codable {
    public let body: CelestialBody
    /// Geocentric ecliptic longitude [0, 360)
    public let longitude: Double
    /// Geocentric ecliptic latitude [-90, 90]
    public let latitude: Double
    public let sign: ZodiacSign
    /// Degree within the sign (0–30)
    public let degreeInSign: Double
    /// True if within 0.5° of a sign boundary
    public let isBoundaryCase: Bool
}
