public enum CelestialBody: String, CaseIterable, Codable, Sendable {
    case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto
    case meanNode, trueNode, lilith
}
