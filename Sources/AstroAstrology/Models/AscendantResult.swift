import AstroCore

public struct AscendantResult: Sendable, Hashable, Codable {
    public let eclipticLongitude: Double
    public let sign: ZodiacSign
    public let degreeInSign: Double
    public let isBoundaryCase: Bool
}
