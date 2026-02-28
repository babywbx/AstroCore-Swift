public enum ZodiacSign: Int, CaseIterable, Codable, Sendable {
    case aries = 0, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    public var name: String {
        switch self {
        case .aries: "Aries"
        case .taurus: "Taurus"
        case .gemini: "Gemini"
        case .cancer: "Cancer"
        case .leo: "Leo"
        case .virgo: "Virgo"
        case .libra: "Libra"
        case .scorpio: "Scorpio"
        case .sagittarius: "Sagittarius"
        case .capricorn: "Capricorn"
        case .aquarius: "Aquarius"
        case .pisces: "Pisces"
        }
    }

    public var emoji: String {
        switch self {
        case .aries: "♈"
        case .taurus: "♉"
        case .gemini: "♊"
        case .cancer: "♋"
        case .leo: "♌"
        case .virgo: "♍"
        case .libra: "♎"
        case .scorpio: "♏"
        case .sagittarius: "♐"
        case .capricorn: "♑"
        case .aquarius: "♒"
        case .pisces: "♓"
        }
    }

    /// Starting longitude of this sign (0, 30, 60, ...)
    public var startLongitude: Double {
        Double(rawValue) * 30.0
    }

    /// Check if a given ecliptic longitude falls within this sign.
    /// Uses left-closed, right-open intervals: [start, start+30)
    public func contains(longitude: Double) -> Bool {
        let normalized = AngleMath.normalized(degrees: longitude)
        let start = startLongitude
        let end = start + 30.0
        if end <= 360.0 {
            return normalized >= start && normalized < end
        }
        // Wraps around 360 (Pisces: 330...<360 or 0)
        return normalized >= start || normalized < (end - 360.0)
    }
}
