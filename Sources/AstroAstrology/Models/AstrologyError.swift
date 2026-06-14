import AstroCore

/// Errors from the astrology overlay. Wraps core errors and adds astrology-only cases.
public enum AstrologyError: Error, Sendable, Equatable {
    /// An error originating in AstroCore (e.g. coordinate validation).
    case core(AstroError)
    /// Ascendant or chart requested without a coordinate.
    case missingCoordinateForAscendant
    /// The requested house system is undefined at this latitude and the caller
    /// elected to receive an error instead of a fallback.
    case houseSystemUndefinedAtLatitude(system: HouseSystem, latitude: Double)
}
