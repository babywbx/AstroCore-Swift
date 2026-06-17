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
        latitude = Double(latitudeE5) / 100000.0
        longitude = Double(longitudeE5) / 100000.0

        timeZoneIdentifier = try container.decode(String.self)

        guard container.isAtEnd else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City row must contain exactly six fields"
            )
        }
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City id must not be empty"
            )
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City name must not be empty"
            )
        }
        guard Self.isValidCountryCode(countryCode) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City country code must be two uppercase ASCII letters"
            )
        }
        guard (-90.0...90.0).contains(latitude),
              (-180.0...180.0).contains(longitude)
        else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City coordinate is outside valid ranges"
            )
        }
        guard TimeZone(identifier: timeZoneIdentifier) != nil else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "City time zone identifier is invalid"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try container.encode(name)
        try container.encode(countryCode)
        try container.encode(Int((latitude * 100000.0).rounded()))
        try container.encode(Int((longitude * 100000.0).rounded()))
        try container.encode(timeZoneIdentifier)
    }

    /// Returns a GeoCoordinate for this city.
    /// City data is pre-validated; throws only if data is corrupted.
    public var coordinate: GeoCoordinate {
        get throws {
            try GeoCoordinate(latitude: latitude, longitude: longitude)
        }
    }

    private static func isValidCountryCode(_ value: String) -> Bool {
        let scalars = value.unicodeScalars
        return scalars.count == 2 && scalars.allSatisfy { scalar in
            scalar.value >= 65 && scalar.value <= 90
        }
    }
}
