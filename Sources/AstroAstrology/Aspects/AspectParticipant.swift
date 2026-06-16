import AstroCore

/// An aspect endpoint: a moving body or a (fixed, natal-frame) chart angle.
public enum AspectParticipant: Sendable, Hashable, Codable {
    case body(CelestialBody)
    case angle(ChartAngle)
}
