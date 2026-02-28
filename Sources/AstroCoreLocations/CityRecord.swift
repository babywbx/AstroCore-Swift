import AstroCore
import Foundation

public struct CityRecord: Identifiable, Sendable, Hashable, Codable {
    public let id: String
    public let name: String
    public let countryCode: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        id = try container.decode(String.self)
        name = try container.decode(String.self)
        countryCode = try container.decode(String.self)

        let latitudeE5 = try container.decode(Int.self)
        let longitudeE5 = try container.decode(Int.self)
        latitude = Double(latitudeE5) / 100_000.0
        longitude = Double(longitudeE5) / 100_000.0

        timeZoneIdentifier = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try container.encode(name)
        try container.encode(countryCode)
        try container.encode(Int((latitude * 100_000.0).rounded()))
        try container.encode(Int((longitude * 100_000.0).rounded()))
        try container.encode(timeZoneIdentifier)
    }

    /// Returns a GeoCoordinate for this city.
    /// City data is pre-validated; throws only if data is corrupted.
    public var coordinate: GeoCoordinate {
        get throws {
            try GeoCoordinate(latitude: latitude, longitude: longitude)
        }
    }
}
