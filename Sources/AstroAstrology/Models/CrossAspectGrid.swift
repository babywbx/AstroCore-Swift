import AstroCore

public struct CrossAspectGrid: Sendable, Equatable, Codable {
    /// Natal-side bodies in CaseIterable order.
    public let natalBodies: [CelestialBody]
    /// Transit-side bodies in CaseIterable order.
    public let transitBodies: [CelestialBody]
    /// Matched directed aspects; natalBody and transitBody are not interchangeable.
    public let aspects: [CrossAspect]

    public init(
        natalBodies: [CelestialBody],
        transitBodies: [CelestialBody],
        aspects: [CrossAspect]
    ) {
        self.natalBodies = natalBodies
        self.transitBodies = transitBodies
        self.aspects = aspects
    }

    /// Directed aspect from one natal body to one transit body.
    public func aspect(natal: CelestialBody, transit: CelestialBody) -> CrossAspect? {
        aspects.first {
            $0.natalBody == natal && $0.transitBody == transit
        }
    }

    public func aspects(natal body: CelestialBody) -> [CrossAspect] {
        aspects.filter { $0.natalBody == body }
    }

    public func aspects(transit body: CelestialBody) -> [CrossAspect] {
        aspects.filter { $0.transitBody == body }
    }
}
