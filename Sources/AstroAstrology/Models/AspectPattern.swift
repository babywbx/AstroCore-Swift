import AstroCore

/// A configuration of bodies recognised on an aspect grid (purely combinatorial, no ephemeris).
public struct AspectPattern: Sendable, Equatable, Codable {
    public let kind: AspectPatternKind
    /// Participating bodies in canonical (CaseIterable) order.
    public let bodies: [CelestialBody]
    /// The grid edges that define the pattern.
    public let aspects: [Aspect]
    /// Focal body for T-Square / Yod; nil otherwise.
    public let apex: CelestialBody?

    public init(kind: AspectPatternKind, bodies: [CelestialBody], aspects: [Aspect], apex: CelestialBody?) {
        self.kind = kind
        self.bodies = bodies
        self.aspects = aspects
        self.apex = apex
    }
}
