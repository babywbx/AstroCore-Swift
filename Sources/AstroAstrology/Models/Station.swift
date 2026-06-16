import AstroCore

/// A planetary station: the instant a body's ecliptic longitude speed crosses zero.
public struct Station: Sendable, Equatable, Codable {
    public let body: CelestialBody
    public let kind: StationKind
    /// Authoritative instant in UT.
    public let julianDayUT: Double
    /// Ecliptic longitude at the station (the "station degree").
    public let longitude: Double

    public init(body: CelestialBody, kind: StationKind, julianDayUT: Double, longitude: Double) {
        self.body = body
        self.kind = kind
        self.julianDayUT = julianDayUT
        self.longitude = longitude
    }
}
