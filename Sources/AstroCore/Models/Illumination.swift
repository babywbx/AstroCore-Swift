public struct Illumination: Sendable, Hashable, Codable {
    /// Phase angle (Sun-body-Earth) in degrees [0, 180]
    public let phaseAngle: Double
    /// Illuminated fraction of the disk, 0...1
    public let illuminatedFraction: Double
    /// Elongation (Sun-Earth-body) in degrees [0, 180]
    public let elongation: Double

    public init(phaseAngle: Double, illuminatedFraction: Double, elongation: Double) {
        self.phaseAngle = phaseAngle
        self.illuminatedFraction = illuminatedFraction
        self.elongation = elongation
    }
}
