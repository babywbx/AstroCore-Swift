import AstroCore

/// One Gauquelin sector boundary.
///
/// Gauquelin sectors are numbered `1...36` in clockwise order, starting from
/// the Ascendant.
public struct GauquelinSector: Sendable, Hashable, Codable {
    public let number: Int
    public let eclipticLongitude: Double
    public let sign: ZodiacSign
    public let degreeInSign: Double
}
