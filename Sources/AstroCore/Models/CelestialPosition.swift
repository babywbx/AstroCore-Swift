public struct CelestialPosition: Sendable, Hashable, Codable {
    public let body: CelestialBody
    /// Geocentric apparent ecliptic longitude [0, 360)
    public let longitude: Double
    /// Geocentric ecliptic latitude [-90, 90]
    public let latitude: Double
    /// Geocentric distance; nil for computed points and until a later phase populates bodies
    public let distance: Double?

    public init(
        body: CelestialBody,
        longitude: Double,
        latitude: Double,
        distance: Double? = nil
    ) {
        self.body = body
        self.longitude = longitude
        self.latitude = latitude
        self.distance = distance
    }
}

struct RawCelestialPosition: Sendable {
    let body: CelestialBody
    /// Geocentric ecliptic longitude [0, 360)
    let longitude: Double
    /// Geocentric ecliptic latitude [-90, 90]
    let latitude: Double
}
