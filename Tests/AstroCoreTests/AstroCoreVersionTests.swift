import AstroCore
import Testing

@Suite("AstroCore scaffold")
struct AstroCoreScaffoldTests {
    @Test func versionIsExposed() {
        #expect(AstroCore.version == "3.0.0")
    }
}
