import AstroCore

/// A retrograde period bounded by its retrograde station (start) and direct station (end).
public struct RetrogradeInterval: Sendable, Equatable, Codable {
    public let body: CelestialBody
    /// Retrograde station (direct → retrograde).
    public let start: Station
    /// Direct station (retrograde → direct).
    public let end: Station

    public init(body: CelestialBody, start: Station, end: Station) {
        self.body = body
        self.start = start
        self.end = end
    }
}
