public struct HorizontalCoordinate: Sendable, Hashable, Codable {
    /// Geometric altitude above the horizon in degrees [-90, 90] (no refraction)
    public let altitude: Double
    /// Azimuth in degrees [0, 360), measured from North, clockwise (East = 90)
    public let azimuth: Double

    public init(altitude: Double, azimuth: Double) {
        self.altitude = altitude
        self.azimuth = azimuth
    }
}
