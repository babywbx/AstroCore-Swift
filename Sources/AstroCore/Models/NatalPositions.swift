public struct NatalPositions: Sendable, Equatable, Codable {
    public let ascendant: AscendantResult?
    public let bodies: [CelestialBody: CelestialPosition]
    public let julianDayUT: Double
    public let deltaT: Double
}
