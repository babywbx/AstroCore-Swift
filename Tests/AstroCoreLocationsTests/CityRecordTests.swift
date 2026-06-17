@testable import AstroCoreLocations
import Foundation
import Testing

@Suite("CityRecord Tests")
struct CityRecordTests {
    private func decodeCity(_ json: String) throws -> CityRecord {
        let data = "[\(json)]".data(using: .utf8)!
        return try JSONDecoder().decode([CityRecord].self, from: data)[0]
    }

    @Test func decodesCompactArrayFormat() throws {
        let data = #"[["1850147","Tokyo","JP",3568950,13969171,"Asia/Tokyo"],["2643743","London","GB",5150853,-12574,"Europe/London"],["5128581","New York City","US",4071427,-7400597,"America/New_York"]]"#
            .data(using: .utf8)!

        let cities = try JSONDecoder().decode([CityRecord].self, from: data)

        #expect(cities.count == 3)
        #expect(cities[0].id == "1850147")
        #expect(cities[0].name == "Tokyo")
        #expect(cities[0].countryCode == "JP")
        #expect(abs(cities[0].latitude - 35.6895) < 0.00001)
        #expect(abs(cities[0].longitude - 139.69171) < 0.00001)
        #expect(cities[0].timeZoneIdentifier == "Asia/Tokyo")

        #expect(cities[1].name == "London")
        #expect(cities[1].countryCode == "GB")
        #expect(abs(cities[1].latitude - 51.50853) < 0.00001)
        #expect(abs(cities[1].longitude - -0.12574) < 0.00001)

        #expect(cities[2].name == "New York City")
        #expect(cities[2].countryCode == "US")
        #expect(abs(cities[2].latitude - 40.71427) < 0.00001)
        #expect(abs(cities[2].longitude - -74.00597) < 0.00001)
    }

    @Test func encodesBackToCompactArrayFormat() throws {
        let data = #"[["2643743","London","GB",5150853,-12574,"Europe/London"]]"#
            .data(using: .utf8)!
        let city = try JSONDecoder().decode([CityRecord].self, from: data)[0]

        let encoded = try JSONEncoder().encode([city])
        let decoded = try JSONSerialization.jsonObject(with: encoded) as? [[Any]]
        let row = try #require(decoded?.first)

        #expect(row[0] as? String == "2643743")
        #expect(row[1] as? String == "London")
        #expect(row[2] as? String == "GB")
        #expect(row[3] as? Int == 5150853)
        #expect(row[4] as? Int == -12574)
        #expect(row[5] as? String == "Europe/London")
    }

    @Test func coordinateBuildsGeoCoordinate() throws {
        let data = #"[["5128581","New York City","US",4071427,-7400597,"America/New_York"]]"#
            .data(using: .utf8)!
        let city = try JSONDecoder().decode([CityRecord].self, from: data)[0]
        let coordinate = try city.coordinate

        #expect(abs(coordinate.latitude - 40.71427) < 0.00001)
        #expect(abs(coordinate.longitude - -74.00597) < 0.00001)
    }

    @Test func decodingRejectsMalformedCompactRows() {
        let malformedRows = [
            #"["1850147","Tokyo","JP",3568950,13969171]"#,
            #"["1850147","Tokyo","JP",3568950,13969171,"Asia/Tokyo","extra"]"#,
            #"["","Tokyo","JP",3568950,13969171,"Asia/Tokyo"]"#,
            #"["1850147","","JP",3568950,13969171,"Asia/Tokyo"]"#,
            #"["1850147","Tokyo","JPN",3568950,13969171,"Asia/Tokyo"]"#,
            #"["1850147","Tokyo","J1",3568950,13969171,"Asia/Tokyo"]"#,
            #"["1850147","Tokyo","JP",9000001,13969171,"Asia/Tokyo"]"#,
            #"["1850147","Tokyo","JP",3568950,18000001,"Asia/Tokyo"]"#,
            #"["1850147","Tokyo","JP",3568950,13969171,""]"#,
            #"["1850147","Tokyo","JP",3568950,13969171,"Invalid/Zone"]"#
        ]

        for row in malformedRows {
            #expect(throws: DecodingError.self) {
                _ = try decodeCity(row)
            }
        }
    }
}
