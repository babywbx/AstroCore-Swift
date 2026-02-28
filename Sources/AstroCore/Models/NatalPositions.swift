public struct NatalPositions: Sendable, Codable {
    public let ascendant: AscendantResult?
    public let bodies: [CelestialBody: CelestialPosition]
    public let julianDayUT: Double
    public let deltaT: Double
}
