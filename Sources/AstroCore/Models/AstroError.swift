public enum AstroError: Error, Sendable, Equatable {
    case invalidCoordinate(detail: String)
    case extremeLatitude
    case invalidCivilMoment(detail: String)
    case invalidTimeZoneIdentifier(String)
    case dateConversionFailed
    case unsupportedYearRange(Int)
}
