/// Strategy when a requested house system is undefined at the given latitude
/// (typically inside the polar circle for semi-arc systems).
public enum PolarFallback: Sendable, Hashable, Codable {
    /// Fall back to Porphyry (the Swiss Ephemeris default).
    case porphyry
    /// Fall back to Equal Houses from ASC.
    case equalASC
    /// Fall back to Whole Sign.
    case wholeSign
    /// Throw `AstroError.houseSystemUndefinedAtLatitude` instead of falling back.
    case error
}
