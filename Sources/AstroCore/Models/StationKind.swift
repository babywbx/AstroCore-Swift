/// Which way a body turns at a station (longitude-speed zero).
public enum StationKind: String, CaseIterable, Codable, Sendable, Hashable {
    /// Direct → retrograde: longitude speed crosses from positive to negative.
    case retrograde
    /// Retrograde → direct: longitude speed crosses from negative to positive.
    case direct
}
