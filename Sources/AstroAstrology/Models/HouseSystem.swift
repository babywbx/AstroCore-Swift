import AstroCore

/// All supported 12-house systems returning 12 cusps.
/// Gauquelin 36-sector sectors are exposed through a dedicated API.
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

    // D. Great-circle projection
    case campanus
    case regiomontanus
    case morinus
    case topocentric
    case horizontal

    /// E. Special
    case meridian
    case carter
}

extension HouseSystem {
    /// True if the system is mathematically undefined above the polar circle (|φ| ≥ ~66.5°).
    ///
    /// Topocentric does not carry the limit: although it approximates Placidus,
    /// its closed-form uses a scaled tan(φ) and stays well-defined up to |φ| < 90°.
    public var hasPolarLimit: Bool {
        switch self {
        case .placidus, .koch, .alcabitius:
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
        case .campanus: "Campanus"
        case .regiomontanus: "Regiomontanus"
        case .morinus: "Morinus"
        case .topocentric: "Topocentric"
        case .horizontal: "Horizontal / Azimuthal"
        case .meridian: "Meridian / Axial Rotation"
        case .carter: "Carter Poli-Equatorial"
        }
    }
}
