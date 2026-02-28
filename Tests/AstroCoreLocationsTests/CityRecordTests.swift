import Foundation
import Testing

@testable import AstroCoreLocations

@Suite("CityRecord Tests")
struct CityRecordTests {
    @Test func decodesCompactArrayFormat() throws {
        let data = #"[["1850147","Tokyo","JP",3568950,13969171,"Asia/Tokyo"]]"#
            .data(using: .utf8)!

        let cities = try JSONDecoder().decode([CityRecord].self, from: data)

        #expect(cities.count == 1)
        #expect(cities[0].id == "1850147")
        #expect(cities[0].name == "Tokyo")
        #expect(cities[0].countryCode == "JP")
        #expect(abs(cities[0].latitude - 35.6895) < 0.00001)
        #expect(abs(cities[0].longitude - 139.69171) < 0.00001)
        #expect(cities[0].timeZoneIdentifier == "Asia/Tokyo")
    }
}
