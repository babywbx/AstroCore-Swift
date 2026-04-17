@testable import AstroCoreLocations
import Testing

@Suite("CityIndex Tests")
struct CityIndexTests {
    @Test func emptyAndWhitespaceQueriesReturnEmpty() {
        #expect(CityIndex.shared.search("").isEmpty)
        #expect(CityIndex.shared.search("   ").isEmpty)

        let results = CityIndex.shared.search("nonexistentcity12345")
        #expect(results.isEmpty)
    }

    @Test func searchTokyoLondonAndNewYork() {
        let results = CityIndex.shared.search("Tokyo", limit: 5)
        #expect(!results.isEmpty)
        #expect(results[0].name == "Tokyo")
        #expect(results[0].countryCode == "JP")

        let london = CityIndex.shared.search("London", limit: 5)
        #expect(!london.isEmpty)
        #expect(london[0].name == "London")
        #expect(london[0].countryCode == "GB")

        let newYork = CityIndex.shared.search("New York", limit: 5)
        #expect(!newYork.isEmpty)
        #expect(newYork.contains { $0.name == "New York City" && $0.countryCode == "US" })
    }

    @Test func searchIsCaseInsensitiveTrimmedAndRespectsLimit() {
        let losAngeles = CityIndex.shared.search("  los angeles  ", limit: 1)
        #expect(losAngeles.count == 1)
        #expect(losAngeles[0].name == "Los Angeles")
    }

    @Test func searchRejectsNonPositiveLimitsWithoutCrashing() {
        #expect(CityIndex.shared.search("Tokyo", limit: 0).isEmpty)
        #expect(CityIndex.shared.search("Tokyo", limit: -1).isEmpty)
    }

    @Test func searchCountryCodeFiltersByCountry() {
        let results = CityIndex.shared.search("JP", limit: 5)
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.countryCode == "JP" })

        let british = CityIndex.shared.search("GB", limit: 20)
        #expect(british.contains { $0.countryCode == "GB" && $0.name == "London" })

        let american = CityIndex.shared.search("US", limit: 20)
        #expect(american.contains { $0.countryCode == "US" && $0.name == "New York City" })
    }

    @Test func cityLookupByIDReturnsExpectedCities() {
        let tokyo = CityIndex.shared.city(forID: "1850147")
        #expect(tokyo?.name == "Tokyo")
        #expect(tokyo?.countryCode == "JP")

        let london = CityIndex.shared.city(forID: "2643743")
        #expect(london?.name == "London")
        #expect(london?.countryCode == "GB")

        let newYork = CityIndex.shared.city(forID: "5128581")
        #expect(newYork?.name == "New York City")
        #expect(newYork?.countryCode == "US")
    }

    @Test func cityLookupReturnsNilForUnknownID() {
        #expect(CityIndex.shared.city(forID: "unknown-city-id") == nil)
    }
}
