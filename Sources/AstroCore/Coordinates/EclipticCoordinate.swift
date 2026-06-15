public struct EclipticCoordinate: Sendable, Hashable, Codable {
    /// Ecliptic longitude in degrees [0, 360)
    public let longitude: Double
    /// Ecliptic latitude in degrees [-90, 90]
    public let latitude: Double
    /// Radial distance in AU; heliocentric when produced by `heliocentric(of:at:)`
    public let distance: Double

    public init(longitude: Double, latitude: Double, distance: Double) {
        self.longitude = longitude
        self.latitude = latitude
        self.distance = distance
    }
}
