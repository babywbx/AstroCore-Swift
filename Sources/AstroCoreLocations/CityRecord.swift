import AstroCore
import Foundation

public struct CityRecord: Identifiable, Sendable, Hashable, Codable {
    public let id: String
    public let name: String
    public let localizedName: String?
    public let countryCode: String
    public let admin1: String?
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String
    public let population: Int?

    /// Returns a GeoCoordinate for this city.
    /// City data is pre-validated; throws only if data is corrupted.
    public var coordinate: GeoCoordinate {
        get throws {
            try GeoCoordinate(latitude: latitude, longitude: longitude)
        }
    }
}
