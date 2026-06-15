import AstroCore

public struct NatalAspects: Sendable, Equatable, Codable {
    /// Resolved motion-rich input states.
    public let states: [CelestialBody: CelestialState]
    /// Upper-triangular aspect grid over the states.
    public let grid: AspectGrid
    /// Optional zodiac ascendant, paralleling NatalStates.ascendant.
    public let ascendant: AscendantResult?

    public init(
        states: [CelestialBody: CelestialState],
        grid: AspectGrid,
        ascendant: AscendantResult?
    ) {
        self.states = states
        self.grid = grid
        self.ascendant = ascendant
    }
}
