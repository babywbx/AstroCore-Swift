import Foundation

public struct GeoCoordinate: Sendable, Hashable, Codable {
    /// Latitude in degrees, north positive. Range: -90...90
    public let latitude: Double
    /// Longitude in degrees, east positive. Range: -180...180
    public let longitude: Double
    /// Elevation above the reference ellipsoid in meters. Defaults to sea level.
    public let elevation: Double

    /// - Throws: `AstroError.invalidCoordinate` if out of range
    public init(latitude: Double, longitude: Double, elevation: Double = 0) throws(AstroError) {
        try Validation.requireFinite(latitude, name: "latitude")
        try Validation.requireFinite(longitude, name: "longitude")
        try Validation.requireFinite(elevation, name: "elevation")

        guard (-90.0...90.0).contains(latitude) else {
            throw .invalidCoordinate(detail: "Latitude \(latitude) out of range -90...90")
        }
        guard (-180.0...180.0).contains(longitude) else {
            throw .invalidCoordinate(detail: "Longitude \(longitude) out of range -180...180")
        }
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }

    /// Validates that the latitude is suitable for ascendant calculation.
    /// - Throws: `AstroError.extremeLatitude` if |latitude| > 85°
    func validateForAscendant() throws(AstroError) {
        guard abs(latitude) <= 85.0 else {
            throw .extremeLatitude
        }
    }

    private enum CodingKeys: String, CodingKey {
        case latitude, longitude, elevation
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let elevation = try container.decodeIfPresent(Double.self, forKey: .elevation) ?? 0
        do {
            self = try GeoCoordinate(latitude: latitude, longitude: longitude, elevation: elevation)
        } catch {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "\(error)")
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        if elevation != 0 {
            try container.encode(elevation, forKey: .elevation)
        }
    }
}
