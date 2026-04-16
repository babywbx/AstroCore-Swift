// All 12-house systems returning 12 cusps.
// Gauquelin 36-sector system is intentionally excluded (separate API in future).
public enum HouseSystem: String, CaseIterable, Sendable, Hashable, Codable {
    // A. Equal division
    case equalASC
    case equalMC
    case wholeSign
    case vehlow

    // B. Quadrant interpolation
    case porphyry
    case sripati

    // C. Semi-arc / time-based
    case placidus
    case koch
    case alcabitius
    case sunshineTreindl
    case sunshineMakransky

    // D. Great-circle projection
    case campanus
    case regiomontanus
    case morinus
    case topocentric
    case krusinski
    case apc

    // E. Special
    case horizontal
    case meridian
    case axialRotation
    case carter
    case pullenSD
    case pullenSR
}

extension HouseSystem {
    /// True if the system is mathematically undefined above the polar circle (|φ| ≥ ~66.5°).
    public var hasPolarLimit: Bool {
        switch self {
        case .placidus, .koch, .alcabitius, .topocentric,
             .sunshineTreindl, .sunshineMakransky:
            true
        default:
            false
        }
    }

    /// Human-readable name.
    public var displayName: String {
        switch self {
        case .equalASC: "Equal (ASC)"
        case .equalMC: "Equal (MC)"
        case .wholeSign: "Whole Sign"
        case .vehlow: "Vehlow Equal"
        case .porphyry: "Porphyry"
        case .sripati: "Sripati"
        case .placidus: "Placidus"
        case .koch: "Koch"
        case .alcabitius: "Alcabitius"
        case .sunshineTreindl: "Sunshine (Treindl)"
        case .sunshineMakransky: "Sunshine (Makransky)"
        case .campanus: "Campanus"
        case .regiomontanus: "Regiomontanus"
        case .morinus: "Morinus"
        case .topocentric: "Topocentric"
        case .krusinski: "Krusinski-Pisa-Goelzer"
        case .apc: "APC"
        case .horizontal: "Horizontal"
        case .meridian: "Meridian"
        case .axialRotation: "Axial Rotation"
        case .carter: "Carter Poli-Equatorial"
        case .pullenSD: "Pullen SD"
        case .pullenSR: "Pullen SR"
        }
    }
}
