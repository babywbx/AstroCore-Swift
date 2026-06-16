@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

struct StationBaselineFixture: Sendable, CustomStringConvertible {
    let body: CelestialBody
    let year: Int
    let month: Int
    let day: Int

    var description: String { "\(body)-\(year)" }
}

private let stationBaselineFixtures: [StationBaselineFixture] = [
    .init(body: .mercury, year: 2020, month: 2, day: 17),
    .init(body: .mars, year: 2020, month: 9, day: 9)
]

@Suite("Station Baselines")
struct StationBaselineTests {
    private static var enabled: Bool {
        ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_BASELINE_VERIFICATION"] == "1"
    }

    @Test(arguments: stationBaselineFixtures)
    func stationLandsOnReferenceSpeedZero(_ fixture: StationBaselineFixture) throws {
        guard Self.enabled else { return }
        let seed = try AstroCalculator.julianDayUT(for: CivilMoment(
            year: fixture.year, month: fixture.month, day: fixture.day,
            hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        ))
        let station = try #require(AstroCalculator.stationJulianDayUT(
            of: fixture.body, nearJulianDayUT: seed, searchWindowDays: 30.0
        ))
        // Reference longitude speed at our station, by central difference of reference longitudes.
        let step = 0.5
        let reference = try AstrologyTestSupport.referenceBodyLongitudes(
            julianDaysUT: [station - step, station + step], bodies: [fixture.body]
        )
        let before = try #require(reference.first?[fixture.body])
        let after = try #require(reference.last?[fixture.body])
        var delta = after - before
        if delta > 180.0 { delta -= 360.0 }
        if delta < -180.0 { delta += 360.0 }
        let referenceSpeed = delta / (2.0 * step)
        #expect(abs(referenceSpeed) < 1e-3, "reference speed at station = \(referenceSpeed) deg/day")
    }
}
