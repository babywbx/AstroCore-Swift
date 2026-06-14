@testable import AstroCore
import Foundation
import Testing

@Suite("Neutral batch")
struct NeutralBatchTests {
    @Test func positionsMatchPerBodyCalls() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let bodies = Set(CelestialBody.allCases)
        let batch = AstroCalculator.positions(of: bodies, at: moment)
        #expect(batch.count == bodies.count)
        for body in bodies {
            #expect(batch[body] == AstroCalculator.planetPosition(body, for: moment))
        }
    }

    @Test func statesMatchPerBodyCalls() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let bodies = Set(CelestialBody.allCases)
        let batch = AstroCalculator.states(of: bodies, at: moment)
        for body in bodies {
            let single = AstroCalculator.celestialState(body, for: moment)
            let state = try #require(batch[body])
            #expect(state.position == single.position)
            #expect(abs(state.speed - single.speed) < 1e-12)
        }
    }
}
