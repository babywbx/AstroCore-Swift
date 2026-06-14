public struct CelestialState: Sendable, Hashable, Codable {
    public let body: CelestialBody
    /// Geocentric apparent ecliptic longitude [0, 360)
    public let longitude: Double
    /// Geocentric ecliptic latitude [-90, 90]
    public let latitude: Double
    /// Daily longitude motion in degrees per day (negative = retrograde)
    public let speed: Double
    /// True when longitude motion is negative.
    public var isRetrograde: Bool { speed < 0 }

    public var position: CelestialPosition {
        CelestialPosition(
            body: body,
            longitude: longitude,
            latitude: latitude
        )
    }
}
