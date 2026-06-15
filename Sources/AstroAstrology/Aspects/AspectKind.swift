import AstroCore

public enum AspectKind: Int, CaseIterable, Codable, Sendable, Hashable {
    // Ptolemaic five hold rawValue 0...4; allCases order is a locked contract.
    case conjunction = 0
    case opposition
    case trine
    case square
    case sextile
    // Minor aspects appended; never reorder.
    case quincunx
    case semisextile
    case semisquare
    case sesquiquadrate
    case quintile
    case biquintile

    public var angleDegrees: Double {
        switch self {
        case .conjunction: 0.0
        case .opposition: 180.0
        case .trine: 120.0
        case .square: 90.0
        case .sextile: 60.0
        case .quincunx: 150.0
        case .semisextile: 30.0
        case .semisquare: 45.0
        case .sesquiquadrate: 135.0
        case .quintile: 72.0
        case .biquintile: 144.0
        }
    }

    public var displayName: String {
        switch self {
        case .conjunction: "Conjunction"
        case .opposition: "Opposition"
        case .trine: "Trine"
        case .square: "Square"
        case .sextile: "Sextile"
        case .quincunx: "Quincunx"
        case .semisextile: "Semisextile"
        case .semisquare: "Semisquare"
        case .sesquiquadrate: "Sesquiquadrate"
        case .quintile: "Quintile"
        case .biquintile: "Biquintile"
        }
    }

    public var symbol: String {
        switch self {
        case .conjunction: "☌"
        case .opposition: "☍"
        case .trine: "△"
        case .square: "□"
        case .sextile: "⚹"
        case .quincunx: "⚻"
        case .semisextile: "⚺"
        case .semisquare: "∠"
        case .sesquiquadrate: "⚼"
        case .quintile: "Q"
        case .biquintile: "bQ"
        }
    }

    public var isMajor: Bool { rawValue <= 4 }

    public var defaultOrbDegrees: Double {
        switch self {
        case .conjunction: 8.0
        case .opposition: 8.0
        case .trine: 8.0
        case .square: 7.0
        case .sextile: 6.0
        case .quincunx: 3.0
        case .semisextile: 2.0
        case .semisquare: 2.0
        case .sesquiquadrate: 2.0
        case .quintile: 2.0
        case .biquintile: 2.0
        }
    }

    /// Scaling applied to body-weighted orbs for the major aspects.
    public var majorOrbScale: Double {
        switch self {
        case .conjunction, .opposition, .trine: 1.0
        case .square: 0.875
        case .sextile: 0.75
        default: 1.0
        }
    }

    public static let ptolemaic: Set<AspectKind> =
        [.conjunction, .opposition, .trine, .square, .sextile]
}
