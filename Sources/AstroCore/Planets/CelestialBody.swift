public enum CelestialBody: String, CaseIterable, Codable, Sendable {
    case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto
    /// Mean lunar north node; Tier 3 definition point.
    case meanNode
    /// Osculating lunar north node; Tier 2, limited by Moon position accuracy.
    case trueNode
    /// Mean Black Moon: bare mean-apogee longitude, ecliptic latitude 0; Tier 3, convention-defined.
    case lilith
    /// Geometric mean Black Moon: mean apogee projected onto the inclined lunar orbit; carries
    /// ecliptic latitude near +/-5 deg; Tier 3, convention-defined.
    case trueLilith
}
