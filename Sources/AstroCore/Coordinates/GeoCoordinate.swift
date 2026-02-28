import Foundation

public struct GeoCoordinate: Sendable, Hashable, Codable {
    /// Latitude in degrees, north positive. Range: -90...90
    public let latitude: Double
    /// Longitude in degrees, east positive. Range: -180...180
    public let longitude: Double

    /// - Throws: `AstroError.invalidCoordinate` if out of range
    public init(latitude: Double, longitude: Double) throws(AstroError) {
        try Validation.requireFinite(latitude, name: "latitude")
        try Validation.requireFinite(longitude, name: "longitude")

        guard (-90.0...90.0).contains(latitude) else {
            throw .invalidCoordinate(detail: "Latitude \(latitude) out of range -90...90")
        }
        guard (-180.0...180.0).contains(longitude) else {
            throw .invalidCoordinate(detail: "Longitude \(longitude) out of range -180...180")
        }
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Validates that the latitude is suitable for ascendant calculation.
    /// - Throws: `AstroError.extremeLatitude` if |latitude| > 85°
    public func validateForAscendant() throws(AstroError) {
        guard abs(latitude) <= 85.0 else {
            throw .extremeLatitude
        }
    }
}
