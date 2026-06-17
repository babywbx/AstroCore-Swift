@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Chart Aspects")
struct ChartAspectTests {
    private func moment() throws -> CivilMoment {
        try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
    }

    private func nyc() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 40.7128, longitude: -74.0)
    }

    private func isBody(_ participant: AspectParticipant) -> Bool {
        if case .body = participant { return true }
        return false
    }

    @Test func bodyOnlyGridMatchesRegularGrid() throws {
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars, .jupiter]
        let grid = try AstrologyCalculator.aspects(for: moment(), bodies: bodies)
        let chart = try AstrologyCalculator.chartAspects(
            for: moment(), coordinate: nyc(), bodies: bodies, angles: []
        )
        let chartBodyAspects = chart.aspects.filter { isBody($0.a) && isBody($0.b) }
        #expect(chartBodyAspects.count == grid.aspects.count)
        for aspect in grid.aspects {
            let match = chart.aspect(between: .body(aspect.bodyA), and: .body(aspect.bodyB))
            #expect(match?.kind == aspect.kind)
            #expect(abs((match?.deviation ?? .nan) - aspect.deviation) < 1e-12)
            #expect(match?.isApplying == aspect.isApplying)
        }
    }

    @Test func angleAxisOppositionsAreDetected() throws {
        let chart = try AstrologyCalculator.chartAspects(
            for: moment(), coordinate: nyc(), bodies: [],
            angles: [.ascendant, .midheaven, .descendant, .imumCoeli]
        )
        let ascDsc = chart.aspect(between: .angle(.ascendant), and: .angle(.descendant))
        #expect(ascDsc?.kind == .opposition)
        #expect(abs(ascDsc?.deviation ?? .nan) < 1e-6)
        let mcIc = chart.aspect(between: .angle(.midheaven), and: .angle(.imumCoeli))
        #expect(mcIc?.kind == .opposition)
        #expect(abs(mcIc?.deviation ?? .nan) < 1e-6)
    }

    @Test func resolverFormsBodyAngleConjunction() {
        let aspect = AspectEngine.resolveChartAspect(
            participantA: .body(.sun), longitudeA: 10.0, speedA: 1.0,
            participantB: .angle(.ascendant), longitudeB: 12.0, speedB: 0.0,
            aspectKinds: AspectKind.ptolemaic, orbPolicy: .default
        )
        #expect(aspect?.kind == .conjunction)
        #expect(aspect?.a == .body(.sun))
        #expect(aspect?.b == .angle(.ascendant))
        #expect(abs((aspect?.deviation ?? .nan) - 2.0) < 1e-9)
        #expect(aspect?.isApplying == true) // Sun at 10 moving +1°/day closes on the fixed angle at 12
    }

    @Test func vertexOmittedWhenUndefined() throws {
        let equator = try GeoCoordinate(latitude: 0.0, longitude: 0.0)
        let chart = try AstrologyCalculator.chartAspects(
            for: moment(), coordinate: equator, bodies: [], angles: [.ascendant, .vertex]
        )
        #expect(chart.participants.contains(.angle(.ascendant)))
        #expect(!chart.participants.contains(.angle(.vertex)))
    }

    @Test func chartAspectGridIsCodable() throws {
        let chart = try AstrologyCalculator.chartAspects(
            for: moment(), coordinate: nyc(), bodies: [.sun, .moon], angles: [.ascendant, .midheaven]
        )
        let data = try JSONEncoder().encode(chart)
        let decoded = try JSONDecoder().decode(ChartAspectGrid.self, from: data)
        #expect(decoded == chart)
    }

    @Test func angleOrbModifierWidensAngleOrb() {
        let widened = OrbPolicy(baseOrbs: OrbPolicy.default.baseOrbs, angleOrbModifier: 10.0)
        let bodyAngle = widened.allowedOrb(
            for: .conjunction, participantA: .body(.sun), participantB: .angle(.ascendant)
        )
        #expect(bodyAngle == 10.0)
        // Body-body still follows the body rule (no body modifiers → base orb).
        let bodyBody = widened.allowedOrb(
            for: .conjunction, participantA: .body(.sun), participantB: .body(.moon)
        )
        #expect(bodyBody == widened.baseOrbs[.conjunction])
    }

    @Test func invalidAngleOrbModifierDoesNotCreateSpuriousAspect() {
        let invalid = OrbPolicy(
            baseOrbs: [.conjunction: 0.0],
            angleOrbModifier: .infinity
        )
        let aspect = AspectEngine.resolveChartAspect(
            participantA: .body(.sun), longitudeA: 0.0, speedA: 1.0,
            participantB: .angle(.ascendant), longitudeB: 90.0, speedB: 0.0,
            aspectKinds: [.conjunction],
            orbPolicy: invalid
        )
        #expect(aspect == nil)
    }
}
