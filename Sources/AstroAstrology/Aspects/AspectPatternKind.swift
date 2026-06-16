import AstroCore

public enum AspectPatternKind: Int, CaseIterable, Codable, Sendable, Hashable {
    // Locked rawValue order; never reorder.
    case stellium = 0
    case grandTrine
    case tSquare
    case grandCross
    case yod
    case mysticRectangle
    case kite

    public var displayName: String {
        switch self {
        case .stellium: "Stellium"
        case .grandTrine: "Grand Trine"
        case .tSquare: "T-Square"
        case .grandCross: "Grand Cross"
        case .yod: "Yod"
        case .mysticRectangle: "Mystic Rectangle"
        case .kite: "Kite"
        }
    }

    /// Canonical body count; the minimum for the variable-size stellium.
    public var bodyCount: Int {
        switch self {
        case .stellium, .grandTrine, .tSquare, .yod: 3
        case .grandCross, .mysticRectangle, .kite: 4
        }
    }
}
