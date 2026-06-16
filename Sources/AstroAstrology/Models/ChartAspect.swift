import AstroCore

/// An aspect between two participants (bodies and/or angles). Angles are fixed (speed 0), so
/// `isApplying` reflects the moving side closing on the fixed side and stays non-optional.
public struct ChartAspect: Sendable, Hashable, Codable {
    public let a: AspectParticipant
    public let b: AspectParticipant
    public let kind: AspectKind
    /// Signed deviation = separation − aspectAngle (deg), in (-allowedOrb, allowedOrb).
    public let deviation: Double
    public let allowedOrb: Double
    public let isApplying: Bool
    public let isExact: Bool

    public var isSeparating: Bool { !isApplying }

    public init(
        a: AspectParticipant,
        b: AspectParticipant,
        kind: AspectKind,
        deviation: Double,
        allowedOrb: Double,
        isApplying: Bool,
        isExact: Bool
    ) {
        self.a = a
        self.b = b
        self.kind = kind
        self.deviation = deviation
        self.allowedOrb = allowedOrb
        self.isApplying = isApplying
        self.isExact = isExact
    }
}
