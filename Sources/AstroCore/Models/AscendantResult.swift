public struct AscendantResult: Sendable, Hashable, Codable {
    public let eclipticLongitude: Double
    public let sign: ZodiacSign
    public let degreeInSign: Double
    public let localSiderealTimeDegrees: Double
    public let julianDayUT: Double
    public let trueObliquity: Double
    public let isBoundaryCase: Bool
}
