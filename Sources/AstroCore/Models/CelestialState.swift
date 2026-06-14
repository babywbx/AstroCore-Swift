public struct CelestialState: Sendable, Hashable, Codable {
    public let body: CelestialBody
    /// Geocentric apparent ecliptic longitude [0, 360)
    public let longitude: Double
    /// Geocentric ecliptic latitude [-90, 90]
    public let latitude: Double
    /// Geocentric distance in AU; nil for computed points.
    public let distance: Double?
    /// Daily longitude motion in degrees per day (negative = retrograde)
    public let speed: Double
    /// True when longitude motion is negative.
    public var isRetrograde: Bool { speed < 0 }

    public init(
        body: CelestialBody,
        longitude: Double,
        latitude: Double,
        distance: Double? = nil,
        speed: Double
    ) {
        self.body = body
        self.longitude = longitude
        self.latitude = latitude
        self.distance = distance
        self.speed = speed
    }

    public var position: CelestialPosition {
        CelestialPosition(
            body: body,
            longitude: longitude,
            latitude: latitude,
            distance: distance
        )
    }
}
