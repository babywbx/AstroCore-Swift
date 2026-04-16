public enum AstroError: Error, Sendable, Equatable {
    case invalidCoordinate(detail: String)
    case extremeLatitude
    case invalidCivilMoment(detail: String)
    case invalidTimeZoneIdentifier(String)
    case dateConversionFailed
    case unsupportedYearRange(Int)
    case missingCoordinateForAscendant
    /// The requested house system is not defined at this latitude and the caller
    /// elected to receive an error instead of a fallback.
    case houseSystemUndefinedAtLatitude(system: HouseSystem, latitude: Double)
    /// The requested house system is planned but not implemented yet.
    case houseSystemNotYetImplemented(system: HouseSystem)
}
