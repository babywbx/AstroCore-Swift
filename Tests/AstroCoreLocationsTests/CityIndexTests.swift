import Testing

@testable import AstroCoreLocations

@Suite("CityIndex Tests")
struct CityIndexTests {
    @Test func emptySearchReturnsEmpty() {
        let results = CityIndex.shared.search("nonexistentcity12345")
        #expect(results.isEmpty)
    }

    @Test func searchTokyo() {
        let results = CityIndex.shared.search("Tokyo", limit: 5)
        #expect(!results.isEmpty)
        #expect(results[0].name == "Tokyo")
        #expect(results[0].countryCode == "JP")
    }

    @Test func searchNewYork() {
        let results = CityIndex.shared.search("New York", limit: 5)
        #expect(!results.isEmpty)
    }

    @Test func popularCities() {
        let cities = CityIndex.shared.popularCities(limit: 10)
        #expect(cities.count == 10)
        #expect((cities[0].population ?? 0) > 1_000_000)
    }

    @Test func cityByID() {
        // Tokyo's GeoNames ID is 1850147
        let city = CityIndex.shared.city(forID: "1850147")
        #expect(city?.name == "Tokyo")
    }
}
