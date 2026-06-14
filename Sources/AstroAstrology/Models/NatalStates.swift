import AstroCore

public struct NatalStates: Sendable, Equatable, Codable {
    public let ascendant: AscendantResult?
    public let bodies: [CelestialBody: CelestialState]
}
