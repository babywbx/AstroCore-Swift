import AstroCore

public struct CrossAspect: Sendable, Hashable, Codable {
    /// Natal-side body.
    public let natalBody: CelestialBody
    /// Transit-side body.
    public let transitBody: CelestialBody
    public let kind: AspectKind
    /// Signed deviation = separation - aspectAngle (deg), in (-allowedOrb, allowedOrb).
    public let deviation: Double
    /// Allowed orb that admitted this aspect.
    public let allowedOrb: Double
    /// Applying (true) / separating (false), using transit motion relative to natal motion.
    public let isApplying: Bool
    /// |deviation| within the partile threshold.
    public let isExact: Bool

    public var isSeparating: Bool { !isApplying }

    public init(
        natalBody: CelestialBody,
        transitBody: CelestialBody,
        kind: AspectKind,
        deviation: Double,
        allowedOrb: Double,
        isApplying: Bool,
        isExact: Bool
    ) {
        self.natalBody = natalBody
        self.transitBody = transitBody
        self.kind = kind
        self.deviation = deviation
        self.allowedOrb = allowedOrb
        self.isApplying = isApplying
        self.isExact = isExact
    }
}
