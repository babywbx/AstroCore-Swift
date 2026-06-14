import AstroAstrology
import Testing

@Suite("AstroAstrology scaffold")
struct AstroAstrologyScaffoldTests {
    @Test func versionIsExposed() {
        #expect(AstroAstrology.version == "3.0.0-dev")
    }
}
