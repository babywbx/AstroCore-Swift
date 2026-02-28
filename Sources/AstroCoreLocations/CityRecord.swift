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

    public var coordinate: GeoCoordinate {
        // Safe: city data is pre-validated
        try! GeoCoordinate(latitude: latitude, longitude: longitude)
    }
}
