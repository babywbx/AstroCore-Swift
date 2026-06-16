/// A chart angle that can participate in aspects alongside bodies.
public enum ChartAngle: Int, CaseIterable, Codable, Sendable, Hashable {
    case ascendant = 0
    case midheaven
    case descendant
    case imumCoeli
    case vertex

    public var displayName: String {
        switch self {
        case .ascendant: "Ascendant"
        case .midheaven: "Midheaven"
        case .descendant: "Descendant"
        case .imumCoeli: "Imum Coeli"
        case .vertex: "Vertex"
        }
    }
}
