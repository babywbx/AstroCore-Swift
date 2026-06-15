@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Aspect Matrix")
struct AspectMatrixTests {
    private static func momentJ2000() throws -> CivilMoment {
        try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
    }

    private static let tenBodies: [CelestialBody] =
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

    @Test func gridComparesExactlyUpperTriangularPairs() {
        var states: [CelestialBody: CelestialState] = [:]
        for (index, body) in Self.tenBodies.enumerated() {
            states[body] = CelestialState(body: body, longitude: Double(index) * 17.0, latitude: 0, speed: 1)
        }
        let result = AspectEngine.buildGrid(
            among: states, aspectKinds: AspectKind.ptolemaic, orbPolicy: .default
        )
        let n = Self.tenBodies.count
        #expect(result.comparisons == n * (n - 1) / 2)
    }

    @Test func gridTriggersStatesProviderExactlyOnce() throws {
        let moment = try Self.momentJ2000()
        var calls = 0
        let result = AspectEngine.gridAspects(
            for: moment,
            bodies: [.sun, .moon, .mars, .venus],
            aspectKinds: AspectKind.ptolemaic,
            orbPolicy: .default,
            statesProvider: { bodies, moment in
                calls += 1
                return AstroCalculator.states(of: bodies, at: moment)
            }
        )
        #expect(calls == 1)
        #expect(result.comparisons == 6)
    }

    @Test func gridMatchesPerPairSingleQueries() throws {
        let moment = try Self.momentJ2000()
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn]
        let grid = try AstrologyCalculator.aspects(for: moment, bodies: bodies)
        let sorted = bodies.sorted { ($0.rawValue) < ($1.rawValue) }
        for outer in 0..<sorted.count {
            for inner in (outer + 1)..<sorted.count {
                let a = sorted[outer]
                let b = sorted[inner]
                let single = try AstrologyCalculator.aspect(between: a, and: b, for: moment)
                #expect(grid.aspect(between: a, and: b) == single)
            }
        }
    }

    @Test func gridHasNoSelfPairsOrDuplicates() throws {
        let moment = try Self.momentJ2000()
        let grid = try AstrologyCalculator.aspects(
            for: moment,
            bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto],
            aspectKinds: Set(AspectKind.allCases)
        )
        var seenPairs = Set<String>()
        for aspect in grid.aspects {
            #expect(aspect.bodyA != aspect.bodyB)
            let orderA = AspectEngine.bodyOrder[aspect.bodyA] ?? -1
            let orderB = AspectEngine.bodyOrder[aspect.bodyB] ?? -1
            #expect(orderA < orderB)
            let key = "\(aspect.bodyA.rawValue)|\(aspect.bodyB.rawValue)"
            #expect(!seenPairs.contains(key))
            seenPairs.insert(key)
        }
    }

    @Test func gridForMomentEqualsGridAmongStates() throws {
        let moment = try Self.momentJ2000()
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars]
        let viaMoment = try AstrologyCalculator.aspects(for: moment, bodies: bodies)
        let states = AstroCalculator.states(of: bodies, at: moment)
        let viaStates = AstrologyCalculator.aspects(among: states)
        #expect(viaMoment == viaStates)
    }

    @Test func gridEmptyAndSingletonAreEmpty() throws {
        let moment = try Self.momentJ2000()
        #expect(try AstrologyCalculator.aspects(for: moment, bodies: []).aspects.isEmpty)
        #expect(try AstrologyCalculator.aspects(for: moment, bodies: [.sun]).aspects.isEmpty)
        #expect(AstrologyCalculator.aspects(among: [:]).aspects.isEmpty)
    }

    @Test func gridRespectsCustomOrbPolicyAtBoundary() {
        // Sun-Saturn square deviation exactly 8.0: outside default (7) but inside luminary-weighted (8.75).
        let states: [CelestialBody: CelestialState] = [
            .sun: CelestialState(body: .sun, longitude: 0, latitude: 0, speed: 1),
            .saturn: CelestialState(body: .saturn, longitude: 98, latitude: 0, speed: 0.03)
        ]
        let strict = AspectEngine.buildGrid(among: states, aspectKinds: [.square], orbPolicy: .default).grid
        #expect(strict.aspect(between: .sun, and: .saturn) == nil)
        let wide = AspectEngine.buildGrid(among: states, aspectKinds: [.square], orbPolicy: .luminariesWeighted).grid
        #expect(wide.aspect(between: .sun, and: .saturn)?.kind == .square)
    }

    @Test func gridRoundTripsThroughJSON() throws {
        let moment = try Self.momentJ2000()
        let grid = try AstrologyCalculator.aspects(
            for: moment, bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter]
        )
        let data = try JSONEncoder().encode(grid)
        let decoded = try JSONDecoder().decode(AspectGrid.self, from: data)
        #expect(decoded == grid)
    }

    // MARK: - A5f cross-chart aspects + NatalAspects

    @Test func crossGridComparesFullProduct() throws {
        let moment = try Self.momentJ2000()
        let natal = AstroCalculator.states(of: [.sun, .moon, .mars], at: moment)
        let transit = AstroCalculator.states(of: [.jupiter, .saturn], at: moment)
        let result = AspectEngine.crossGrid(
            natal: natal, transit: transit,
            aspectKinds: AspectKind.ptolemaic, orbPolicy: .default
        )
        #expect(result.comparisons == 6)
    }

    @Test func crossAspectsSelfUpperTriangleEqualsGrid() throws {
        let moment = try Self.momentJ2000()
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn]
        let states = AstroCalculator.states(of: bodies, at: moment)
        let cross = AstrologyCalculator.crossAspects(
            natal: states, transit: states, aspectKinds: Set(AspectKind.allCases)
        )
        let grid = AstrologyCalculator.aspects(among: states, aspectKinds: Set(AspectKind.allCases))
        let upper = cross.aspects.filter {
            (AspectEngine.bodyOrder[$0.bodyA] ?? -1) < (AspectEngine.bodyOrder[$0.bodyB] ?? -1)
        }
        #expect(Set(upper) == Set(grid.aspects))
    }

    @Test func crossAspectsIncludeSameBodyReturn() {
        let natal: [CelestialBody: CelestialState] = [
            .sun: CelestialState(body: .sun, longitude: 100, latitude: 0, speed: 1)
        ]
        let transit: [CelestialBody: CelestialState] = [
            .sun: CelestialState(body: .sun, longitude: 100.5, latitude: 0, speed: 1)
        ]
        let cross = AstrologyCalculator.crossAspects(natal: natal, transit: transit)
        #expect(cross.aspects.count == 1)
        #expect(cross.aspects.first?.kind == .conjunction)
        #expect(cross.aspects.first?.bodyA == .sun)
        #expect(cross.aspects.first?.bodyB == .sun)
    }

    @Test func natalAspectsProducerAssemblesGridAndAscendant() throws {
        let fixture = try AstrologyTestSupport.newYork1990()
        let result = try AstrologyCalculator.natalAspects(
            for: fixture.moment, coordinate: fixture.coordinate,
            bodies: [.sun, .moon, .mercury, .venus, .mars], includeAscendant: true
        )
        #expect(result.ascendant != nil)
        #expect(result.states.count == 5)
        #expect(result.grid == AstrologyCalculator.aspects(among: result.states))
    }

    @Test func natalAspectsRoundTripsThroughJSON() throws {
        let fixture = try AstrologyTestSupport.newYork1990()
        let result = try AstrologyCalculator.natalAspects(
            for: fixture.moment, bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter]
        )
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(NatalAspects.self, from: data)
        #expect(decoded == result)
    }
}
