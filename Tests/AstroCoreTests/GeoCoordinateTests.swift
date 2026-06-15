@testable import AstroCore
import Foundation
import Testing

@Suite("GeoCoordinate Elevation")
struct GeoCoordinateTests {
    @Test func defaultsToSeaLevel() throws {
        let c = try GeoCoordinate(latitude: 51.0, longitude: -0.1)
        #expect(c.elevation == 0.0)
    }

    @Test func storesElevation() throws {
        let c = try GeoCoordinate(latitude: 51.0, longitude: -0.1, elevation: 1650.0)
        #expect(c.elevation == 1650.0)
    }

    @Test func rejectsNonFiniteElevation() {
        #expect(throws: AstroError.self) {
            _ = try GeoCoordinate(latitude: 0, longitude: 0, elevation: .nan)
        }
    }

    @Test func decodingMissingElevationDefaultsToZero() throws {
        let json = #"{"latitude":51.0,"longitude":-0.1}"#.data(using: .utf8)!
        let c = try JSONDecoder().decode(GeoCoordinate.self, from: json)
        #expect(c.elevation == 0.0)
    }

    @Test func encodingOmitsZeroElevation() throws {
        let c = try GeoCoordinate(latitude: 51.0, longitude: -0.1)
        let json = try #require(String(data: JSONEncoder().encode(c), encoding: .utf8))
        #expect(!json.contains("elevation"))
    }

    @Test func roundTripsNonZeroElevation() throws {
        let c = try GeoCoordinate(latitude: 51.0, longitude: -0.1, elevation: 1650.0)
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(GeoCoordinate.self, from: data)
        #expect(back == c)
        #expect(try #require(String(data: data, encoding: .utf8)?.contains("elevation")))
    }
}
