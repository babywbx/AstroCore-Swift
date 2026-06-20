import AstroCoreLocations
import Testing

@Suite("AstroCoreLocations scaffold")
struct AstroCoreLocationsScaffoldTests {
    @Test func versionIsExposed() {
        #expect(AstroCoreLocations.version == "3.0.0")
    }
}
