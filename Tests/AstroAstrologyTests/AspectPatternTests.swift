@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Aspect Patterns")
struct AspectPatternTests {
    private func edge(_ a: CelestialBody, _ b: CelestialBody, _ kind: AspectKind) -> Aspect {
        Aspect(
            bodyA: a, bodyB: b, kind: kind, deviation: 0.0,
            allowedOrb: kind.defaultOrbDegrees, isApplying: false, isExact: true
        )
    }

    private func grid(
        _ bodies: [CelestialBody], _ edges: [(CelestialBody, CelestialBody, AspectKind)]
    ) -> AspectGrid {
        AspectGrid(bodies: bodies, aspects: edges.map { edge($0.0, $0.1, $0.2) })
    }

    private func find(
        _ patterns: [AspectPattern], _ kind: AspectPatternKind, _ bodies: Set<CelestialBody>
    ) -> AspectPattern? {
        patterns.first { $0.kind == kind && Set($0.bodies) == bodies }
    }

    @Test func grandTrineFromThreeTrines() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars],
            [(.sun, .moon, .trine), (.moon, .mars, .trine), (.sun, .mars, .trine)]
        ))
        let pattern = find(patterns, .grandTrine, [.sun, .moon, .mars])
        #expect(pattern != nil)
        #expect(pattern?.apex == nil)
        #expect(pattern?.bodies == [.sun, .moon, .mars]) // canonical order
    }

    @Test func tSquareHasApexAtThirdBody() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars],
            [(.sun, .moon, .opposition), (.sun, .mars, .square), (.moon, .mars, .square)]
        ))
        let pattern = try? #require(find(patterns, .tSquare, [.sun, .moon, .mars]))
        #expect(pattern?.apex == .mars)
    }

    @Test func grandCrossFromTwoOppositionsAndFourSquares() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .venus, .mars],
            [
                (.sun, .moon, .opposition), (.venus, .mars, .opposition),
                (.sun, .venus, .square), (.sun, .mars, .square),
                (.moon, .venus, .square), (.moon, .mars, .square)
            ]
        ))
        #expect(find(patterns, .grandCross, [.sun, .moon, .venus, .mars]) != nil)
    }

    @Test func yodHasApexAtQuincunxFocus() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars],
            [(.sun, .moon, .sextile), (.sun, .mars, .quincunx), (.moon, .mars, .quincunx)]
        ))
        let pattern = find(patterns, .yod, [.sun, .moon, .mars])
        #expect(pattern?.apex == .mars)
    }

    @Test func stelliumNeedsAFullClique() {
        let cliquePatterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mercury],
            [(.sun, .moon, .conjunction), (.moon, .mercury, .conjunction), (.sun, .mercury, .conjunction)]
        ))
        #expect(find(cliquePatterns, .stellium, [.sun, .moon, .mercury]) != nil)

        // A-B, B-C conjunct but A-C missing → no three-body stellium.
        let chainPatterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mercury],
            [(.sun, .moon, .conjunction), (.moon, .mercury, .conjunction)]
        ))
        #expect(chainPatterns.allSatisfy { $0.kind != .stellium })
    }

    @Test func mysticRectangleFromTwoOppositionsTrinesSextiles() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .venus, .mars],
            [
                (.sun, .moon, .opposition), (.venus, .mars, .opposition),
                (.sun, .venus, .sextile), (.moon, .mars, .sextile),
                (.sun, .mars, .trine), (.moon, .venus, .trine)
            ]
        ))
        #expect(find(patterns, .mysticRectangle, [.sun, .moon, .venus, .mars]) != nil)
    }

    @Test func kiteFromGrandTrinePlusOpposition() {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars, .venus],
            [
                (.sun, .moon, .trine), (.moon, .mars, .trine), (.sun, .mars, .trine),
                (.sun, .venus, .opposition), (.moon, .venus, .sextile), (.mars, .venus, .sextile)
            ]
        ))
        #expect(find(patterns, .kite, [.sun, .moon, .mars, .venus]) != nil)
    }

    @Test func nearMissIsNotDetected() {
        // Grand trine missing one edge: only two trines present.
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars],
            [(.sun, .moon, .trine), (.moon, .mars, .trine)]
        ))
        #expect(patterns.allSatisfy { $0.kind != .grandTrine })
    }

    @Test func emptyGridHasNoPatterns() {
        #expect(AstrologyCalculator.patterns(in: grid([.sun, .moon], [])).isEmpty)
    }

    @Test func patternsAreCodableAndDeduplicated() throws {
        let patterns = AstrologyCalculator.patterns(in: grid(
            [.sun, .moon, .mars],
            [(.sun, .moon, .trine), (.moon, .mars, .trine), (.sun, .mars, .trine)]
        ))
        let grandTrines = patterns.filter { $0.kind == .grandTrine }
        #expect(grandTrines.count == 1) // single dedup'd entry
        let data = try JSONEncoder().encode(patterns)
        let decoded = try JSONDecoder().decode([AspectPattern].self, from: data)
        #expect(decoded == patterns)
    }
}
