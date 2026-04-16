/// Four primary chart angles plus Vertex, all as ecliptic longitudes in [0, 360).
public struct Angles: Sendable, Hashable, Codable {
    /// Ascendant (eastern horizon ∩ ecliptic).
    public let ascendant: Double
    /// Midheaven / Medium Coeli (meridian ∩ ecliptic, above horizon).
    public let midheaven: Double
    /// Descendant = ASC + 180°.
    public let descendant: Double
    /// Imum Coeli = MC + 180°.
    public let imumCoeli: Double
    /// Vertex (western intersection of prime vertical with ecliptic).
    /// Nil when |latitude| ≈ 0° (degenerate).
    public let vertex: Double?

    public init(
        ascendant: Double,
        midheaven: Double,
        vertex: Double? = nil
    ) {
        self.ascendant = ascendant
        self.midheaven = midheaven
        self.descendant = Self.oppose(ascendant)
        self.imumCoeli = Self.oppose(midheaven)
        self.vertex = vertex
    }

    private static func oppose(_ longitude: Double) -> Double {
        var value = longitude + 180.0
        if value >= 360.0 { value -= 360.0 }
        return value
    }
}
