import Testing

@testable import AstroCoreLocations

@Suite("CityIndex Tests")
struct CityIndexTests {
    @Test func emptySearchReturnsEmpty() {
        let results = CityIndex.shared.search("nonexistentcity12345")
        #expect(results.isEmpty)
    }
}
