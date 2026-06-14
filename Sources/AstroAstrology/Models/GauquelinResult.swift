import AstroCore

/// Result of a Gauquelin-sector computation.
///
/// `sectors[0]` is sector 1. Numbering follows the library's clockwise
/// sector convention rather than the counterclockwise 12-house convention.
public struct GauquelinResult: Sendable, Hashable, Codable {
    public let sectors: [GauquelinSector]
    public let angles: Angles
}
